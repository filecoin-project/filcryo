#!/bin/bash

set -euxo pipefail

START_EPOCH=$1

echo "Launching lotus daemon with downloaded snapshot"
# Import snapshot
lotus daemon  --import-snapshot snapshot_${START_EPOCH}_*.car 2>&1 > lotus.log

let "END_EPOCH=${START_EPOCH}+2880+15"
let "START_EXPORT_EPOCH=${START_EPOCH}+2880"
let "END_EXPORT_EPOCH=${START_EPOCH}+2880+10"

echo "Waiting for Lotus to sync 24h until ${END_EPOCH}"
# Wait for lotus to sync 2880 epocs
while true; do
    current_height=`lotus chain list --count 1 | cut -d ':' -f 1`
    echo "current height: ${current_height}"

    if [[ "${current_height}" -ge "${END_EPOCH}" ]]; then
	break
    fi
    sleep 10
done

echo "Exporting snapshot from ${START_EXPORT_EPOCH} until ${END_EXPORT_EPOCH}"
lotus chain export-range --internal --messages --receipts --stateroots --workers 50 --tail "@${END_EXPORT_EPOCH}" --head @${START_EPOCH} --write-buffer=5000000 export.car

# We are fully synced. Shutdown
kill %1
wait








