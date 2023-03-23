#!/bin/bash

# Entrypoint for the docker container:
# 1. Initialize and run lotus
# 2. Export metrics
# 3. Follow and upload snapshots

set -ueo pipefail

# We will recommend mounting /root for persistent storage
cp /scripts/*.sh /root
mkdir -p /root/metrics

pushd /root
. filcryo.sh
. exporter_lib.sh

if [[ ! -d .lotus ]]; then # initialize from latest snapshot
    last_epoch=$(get_last_snapshot_epoch)
    rm -rf downloaded_snapshots # clean leftovers
    download_snapshot "${last_epoch}"
    lotus daemon --bootstrap=false --halt-after-import --import-snapshot downloaded_snapshots/*_"${last_epoch}"_*.car
fi

# Start lotus and follow chain
# shellcheck disable=SC2119
start_lotus

function metrics {
    mkdir -p metrics
    pushd metrics
    metrics_prefix="filcryo"
    metrics_array=()

    while true; do
	metrics_array=()
	height=$(lotus chain list --count 1 | cut -d ':' -f 1)
	exporter_add_metric "height" "counter" "Lotus current epoch" "${height}"

	if [[ -f last_uploaded_snapshot_size ]]; then
	    exporter_add_metric "last_uploaded_snapshot_size" "counter" "Size of the latest uploaded snapshot (compressed)" "$(cat last_uploaded_snapshot_size)"
	fi

	if [[ -f latest_snapshot_epoch ]]; then
	    exporter_add_metric "latest_snapshot_epoch" "counter" "Latest epoch included in the latest snapshot" "$(cat latest_snapshot_epoch)"
	fi

	if [[ -f export_duration ]]; then
	    exporter_add_metric "export_duration" "counter" "Duration of the export step" "$(cat export_duration)"
	fi

	if [[ -f exported_snapshot_size ]]; then
	    exporter_add_metric "exported_snapshot_size" "counter" "Size of the exported snapshot" "$(cat exported_snapshot_size)"
	fi

	if [[ -f stateroot_size ]]; then
	    exporter_add_metric "stateroot_size" "counter" "Size of a single stateroot" "$(cat stateroot_size)"
	fi

	if [[ -f compress_duration ]]; then
	    exporter_add_metric "compress_duration" "counter" "Duration of the snapshot compression" "$(cat compress_duration)"
	fi

	if [[ -f upload_duration ]]; then
	    exporter_add_metric "upload_duration" "counter" "Duration of the snapshot upload" "$(cat upload_duration)"
	fi

	## Atomic rename so that we do not read the prom file while writing it.
	exporter_show_metrics > metrics.prom$$
	mv metrics.prom$$ metrics.prom
	sleep 30
    done
}

# Collect metrics
metrics &

ONLY_SYNC="${FILCRYO_ONLY_SYNC:-false}"

if [ "${ONLY_SYNC}" = "true" ]; then
    while true; do
	echo "Filcryo is just syncing and not snapshotting"
	sleep 600
    done
fi


# While(true): make snapshots
while true; do
    size=$(get_last_uploaded_snapshot_size)
    echo "${size}" > last_uploaded_snapshot_size
    mv last_uploaded_snapshot_size metrics/

    start=$(get_last_epoch)
    echo "${start}" > metrics/latest_snapshot_epoch
    wait_for_epoch "${start}"

    export_start_time=$(date '+%s')
    export_range "${start}"
    export_end_time=$(date '+%s')
    (( "export_duration=${export_end_time}-${export_start_time}" ))
    # shellcheck disable=SC2154
    echo "${export_duration}" > export_duration
    mv export_duration metrics/

    get_exported_snapshot_size "${start}" > exported_snapshot_size
    mv exported_snapshot_size metrics/

    get_stateroot_size "${start}" > stateroot_size
    mv stateroot_size metrics/

    compress_start_time=$(date '+%s')
    compress_snapshot "${start}"
    compress_end_time=$(date '+%s')
    (( "compress_duration=${compress_end_time}-${compress_start_time}" ))
    # shellcheck disable=SC2154
    echo "${compress_duration}" > compress_duration
    mv compress_duration metrics/

    upload_start_time=$(date '+%s')
    upload_snapshot "${start}"
    upload_end_time=$(date '+%s')
    (( "upload_duration=${upload_end_time}-${upload_start_time}" ))
    # shellcheck disable=SC2154
    echo "${upload_duration}" > upload_duration
    mv upload_duration metrics/

    sleep 10
done
