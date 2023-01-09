#!/bin/bash

# Entrypoint for the docker container:
# 1. Initialize and run lotus
# 2. Follow and upload snapshots

set -ueo pipefail

# We will recommend mounting /root for persistent storage
cp /scripts/*.sh /root
pushd /root
. filcryo.sh

if [[ ! -d .lotus ]]; then # initialize from latest snapshot
    last_epoch=$(get_last_snapshot_epoch)
    download_snapshot "${last_epoch}"
    lotus daemon --bootstrap=false --halt-after-import --import-snapshot downloaded_snapshots/*_"${last_epoch}"_*.car
fi

# Start lotus and follow chain
# shellcheck disable=SC2119
start_lotus
while true; do
    start=$(get_last_epoch)
    wait_for_epoch "${start}"
    export_range "${start}"
    compress_snapshot "${start}"
    upload_snapshot "${start}"
    sleep 10
done
