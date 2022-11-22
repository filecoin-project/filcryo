#!/usr/bin/env bash
#
# Usage: send_export_jobs.sh [SNAPSHOT_LIST_FILE] [--dry-run]

SNAPSHOT_LIST_FILE=$1

# Read list of snapshots from file
SNAPSHOT_LIST=$(cat "$SNAPSHOT_LIST_FILE")

# Iterate over snapshots
for SNAPSHOT in ${SNAPSHOT_LIST}; do
    # Split name by / and get the second element
    SNAPSHOT_NAME=$(basename "${SNAPSHOT}")
    # Split name by _ and get second element
    SNAPSHOT_EPOCH_FROM=$(echo "${SNAPSHOT_NAME}" | cut -d'_' -f2)
    # Split name by _ and get third element
    SNAPSHOT_EPOCH_TO=$(echo "${SNAPSHOT_NAME}" | cut -d'_' -f3)

    export SNAPSHOT_NAME

    # If dry run, just print the command
    if [[ "$2" == "--dry-run" ]]; then
        echo "Scheduling ${SNAPSHOT_NAME} covering from ${SNAPSHOT_EPOCH_FROM} to ${SNAPSHOT_EPOCH_TO}"
    else
        # Pad the epoch with 0s to 10 digits
        PADDED_SNAPSHOT_EPOCH_FROM=$(printf "%010d" "$SNAPSHOT_EPOCH_FROM")
        PADDED_SNAPSHOT_EPOCH_TO=$(printf "%010d" "$SNAPSHOT_EPOCH_TO")
        envsubst < gce_batch_job.json | gcloud --billing-project protocol-labs-data beta batch jobs submit lily-job-gcs-backfill-snapshot-"$PADDED_SNAPSHOT_EPOCH_FROM"-"$PADDED_SNAPSHOT_EPOCH_TO"-"$(date +%s)" --location europe-north1 --config=-
    fi
done
