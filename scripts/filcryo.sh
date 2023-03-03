#!/bin/bash

set -uo pipefail

BILLING_PROJECT="protocol-labs-data"

# export_range instructs lotus to do a chain export from the given height until 2890 epochs later.
function export_range {
    local START="$1"
    local END
    (( "END=${START}+2880" ))
    echo "Exporting snapshot from ${START} until ${END} (+10 extra)"
    (( "END+=10" ))

    # Remove any leftover snapshots for the same epoch before we start exporting it.
    # Leftovers may happen if the process OOMs.
    rm -f .lotus/snapshot_"${START}"_*.car

    lotus chain export-range --internal --messages --receipts --stateroots --workers 50 --head "@${END}" --tail "@${START}" --write-buffer=5000000 export.car
    echo "Finished exporting snapshot from ${START} until ${END}"
    pushd /root/.lotus || return 1
    
    # Deal with null rounds happening just when the snapshot starts.
    # These will result in the START date being one or several epochs before (consecutive null rounds)
    local i=0
    local actual_start="${START}"
    local snapshot_name
    while [[ "$i" -lt 10 ]]; do
	(( "actual_start=${START}-${i}" ))
	snapshot_name=$(compgen -G snapshot_"${actual_start}"_*.car || true)
	if [[ -z "${snapshot_name}" ]]; then
	    (( "i++" ))
	else # found it
	    if [[ "$i" -eq 0 ]]; then
		break # normal case, no need to rename
	    fi
	    local fixed_name
	    # shellcheck disable=SC2001
	    fixed_name=$(echo "${snapshot_name}" | sed "s/snapshot_${actual_start}_\(.*\)/snapshot_${START}_\1/g")
	    echo "WARNING: Snapshot has unexpected name (probably due to null epochs)."
	    echo "WARNING: ${snapshot_name} will be renamed to ${fixed_name}"
	    mv "${snapshot_name}" "${fixed_name}"
	    break
	fi
    done
    if [[ "$i" -ge 10 ]]; then
	echo "ERROR: expected snapshot file not found"
	return 1
    fi
    
    popd || return 1

    mkdir -p finished_snapshots
    # Remove any failed-upload snapshots
    rm -f finished_snapshots/snapshot_"${START}"_*.car
    mv /root/.lotus/snapshot_"${START}"_*.car finished_snapshots/
    return 0
}

# compress_snapshot compresses a snapshot starting on the given epoch.
function compress_snapshot {
    local START=$1

    pushd finished_snapshots || return 1
    echo "Compressing snapshot for ${START}"
    zstd --fast --rm --no-progress -T0 snapshot_"${START}"_*.car && \
	echo "Finished compressing snapshot for ${START}"
    popd || return 1
    return 0
}

# download_snapshot downloads the snapshot for the given epoch from gcloud storage and decompresses it.
function download_snapshot {
    local START=$1

    # Verify the snapshot exists. Exits with error otherwise.
    snapshot_url=$(gcloud --billing-project="${BILLING_PROJECT}" storage ls "gs://fil-mainnet-archival-snapshots/historical-exports/snapshot_${START}_*_*.car.zst") || return 1

    snapshot_name=$(basename "${snapshot_url}")
    mkdir -p downloaded_snapshots
    pushd downloaded_snapshots || return 1
    gcloud --billing-project="${BILLING_PROJECT}" storage cp "${snapshot_url}" .
    zstd --rm -d "${snapshot_name}"
    popd || return 1

    echo "Snapshot downloaded and decompressed successfully"
    return 0
}

# get_last_epoch prints the last epoch available in the bucket. This is the
# epoch on which the next snapshot should start.
function get_last_epoch {
    # snapshot_2295360_2298242_1667419153.car.zst
    # -> 2295360 + 2880
    # -> 2298240

    local last_epoch
    # FIXME: I think this can fail silently
    last_epoch=$(gcloud --billing-project="${BILLING_PROJECT}" storage ls gs://fil-mainnet-archival-snapshots/historical-exports/ | xargs -n1 basename | cut -d'_' -f 2 | sort -n | tail -n1)
    (( "last_epoch=${last_epoch}+2880" ))
    echo "${last_epoch}"
    return 0
}

# get_last_snapshot_epoch returns the epoch of the last available snapshot so it can be used with
# download_snapshot
function get_last_snapshot_epoch {
    local last_epoch
    last_epoch=$(gcloud --billing-project="${BILLING_PROJECT}" storage ls gs://fil-mainnet-archival-snapshots/historical-exports/ | xargs -n1 basename | cut -d'_' -f 2 | sort -n | tail -n1)
    echo "${last_epoch}"
    return 0
}

# get_last_snapshot_size returns the size of the last available snapshot.
function get_last_snapshot_size {
    local last_epoch
    last_epoch=$(get_last_snapshot_epoch)
    size=$(gcloud --billing-project="${BILLING_PROJECT}" storage ls -l "gs://fil-mainnet-archival-snapshots/historical-exports/*_${last_epoch}_*" | head -n1 | cut -d ' ' -f 1)
    echo "${size}"
    return 0
}

# import_snapshot imports an snapshot corresponding to the given epoch into lotus with --halt-after-import.
function import_snapshot {
    local START=$1

    echo "Importing snapshot"
    lotus daemon --import-snapshot snapshot_"${START}"_*.car --halt-after-import
    return 0
}

# start_lotus launches lotus daemon with the given daemon arguments and waits until it is running.
function start_lotus {
    echo "Launching Lotus daemon: ${1:-}"
    # shellcheck disable=SC2086
    mkdir -p logs
    nohup lotus daemon ${1:-} &>>logs/lotus.log & # run in background!
    echo "Waiting for lotus to start"
    while ! lotus sync status; do
	sleep 10
    done
    sleep 5
    return 0
}

# stop_lotus stops the lotus daemon gracefully
function stop_lotus {
    echo "Shutting down lotus"
    lotus daemon stop
    sleep 20
    return 0
}

# upload_snapshot uploads the snapshot for the given epoch to the gcloud storage bucket.
function upload_snapshot {
    local START=$1

    pushd finished_snapshots || return 1
    echo "Uploading snapshot for ${START}"
    gcloud config set storage/parallel_composite_upload_enabled False
    gcloud --billing-project="${BILLING_PROJECT}" storage cp snapshot_"${START}"_*.car.zst "gs://fil-mainnet-archival-snapshots/historical-exports/"
    echo "Finished uploading snapshot for ${START}"
    rm snapshot_"${START}"_*.car.zst
    popd || return 1
    return 0
}

# wait_for_epoch waits for lotus to be synced up to the given epoch + 2880 +
# 905 epochs: otherwise said, it waits until we can make a 24h snapshot that
# starts on the given epoch, with the end epoch having reached finality.
function wait_for_epoch {
    local START="$1"
    local END
    (( "END=${START}+2880+900+5" ))

    echo "Waiting for Lotus to sync until ${END}"

    while true; do
	local current_height
	current_height=$(lotus chain list --count 1 | cut -d ':' -f 1) || { sleep 1; continue; }
	if [[ $(( "${current_height} % 20" )) -eq 0 ]]; then
	    echo "Current Lotus height: ${current_height}"
	fi

	if [[ "${current_height}" -ge "${END}" ]]; then
	    break
	fi
	sleep 30
    done
    echo "Lotus reached ${END}"
}
