#!/usr/bin/env bash
#
# Usage: ./export.sh [SNAPSHOT_FILE] [EXPORT_DIR]

set -eox pipefail

SNAPSHOT_FILE="${1}"

# Error if the snapshot file is not provided
if [[ -z "${SNAPSHOT_FILE}" ]]; then
  echo "Please provide a snapshot file."
  exit 1
fi

export GOLOG_LOG_FMT=json
EXPORT_DIR="${2:-$(pwd)}"
REPO_PATH="${REPO_PATH:-"/var/lib/lily"}"
WALK_EPOCHS="${WALK_EPOCHS:-"2880"}"

# If the snapshot is compressed, extract it into tmp
if [[ "${SNAPSHOT_FILE}" == *.zst ]]; then
  unzstd "${SNAPSHOT_FILE}" -o /tmp/snapshot.car
fi

# Start Lily
echo "Initializing Lily repository with ${SNAPSHOT_FILE}"
lily init --config /lily/config.toml --repo "${REPO_PATH}" --import-snapshot /tmp/snapshot.car
nohup lily daemon --repo="${REPO_PATH}" --config=/lily/config.toml --bootstrap=false &> lily.log &

# Wait for Lily to come online
lily wait-api

# Extract the walking epochs
FROM_EPOCH=$(echo "${SNAPSHOT_FILE}" | cut -d'_' -f2)
TO_EPOCH=$((FROM_EPOCH + WALK_EPOCHS))

echo "Walking from epoch ${FROM_EPOCH} to ${TO_EPOCH}"
sleep 10

# Run export
archiver run --storage-path /tmp/data --ship-path "${EXPORT_DIR}" --min-height="${FROM_EPOCH}" --max-height="${TO_EPOCH}"

# Alternatively, we could run the export with lily
# lily job run --storage=CSV walk --from "${FROM_EPOCH}" --to "${TO_EPOCH}"
# lily job wait --id 1 && lily stop
# Check there are no errors on visor_processing_reports.csv
# if grep -q "ERROR" /tmp/data/visor_processing_reports.csv; then
#   echo "Errors found on visor_processing_reports!"
#   exit 1
# fi

# Compress the CSV files
# gzip /tmp/data/*.csv

# Move files to export dir
# echo "Saving CSV files to ${EXPORT_DIR}"
# FILENAME=$(basename "${SNAPSHOT_FILE}" .car.zst)
# mkdir -p "$EXPORT_DIR"/"$FILENAME"/
# mv /tmp/data/*.csv.gz "$EXPORT_DIR"/"$FILENAME"/
# mv lily.log "$EXPORT_DIR"/"$FILENAME"/
