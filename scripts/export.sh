#!/usr/bin/env bash
#
# Usage: ./export.sh [SNAPSHOT_FILE] [EXPORT_DIR]

set -euox pipefail

SNAPSHOT_FILE="${1}"

# Error if the snapshot file is not provided
if [[ -z "${SNAPSHOT_FILE}" ]]; then
  echo "Please provide a snapshot file."
  exit 1
fi

export GOLOG_LOG_FMT="json"
export GOLOG_LOG_LEVEL="debug"
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

# Extract the available walking epochs
STATE=$(lily chain state-inspect -l 3000)
# FROM_EPOCH=$(echo "${SNAPSHOT_FILE}" | cut -d'_' -f2)
FROM_EPOCH=$(echo "${STATE}" | jq -r ".summary.stateroots.oldest")
FROM_EPOCH=$((FROM_EPOCH + 1))
# Add WALKEPOCHS to the FROM_EPOCH
TO_EPOCH=$((FROM_EPOCH + WALK_EPOCHS))
# TO_EPOCH=$(echo "${STATE}" | jq -r ".summary.stateroots.newest")

echo "Walking from epoch ${FROM_EPOCH} to ${TO_EPOCH}"
sleep 10

# Run export
archiver export --storage-path /tmp/data --ship-path /tmp/data --min-height="${FROM_EPOCH}" --max-height="${TO_EPOCH}"

# Copy the exported data to the export directory
cp -r /tmp/data/mainnet/ "${EXPORT_DIR}"

# Alternatively, we could run the export with lily
# lily job run --storage=CSV walk --from "${FROM_EPOCH}" --to "${TO_EPOCH}"
# lily job wait --id 1

# # Fail if job error is not empty string
# JOB_ERROR=$(lily job list | jq ".[0]" | jq -r ".Error")
# if [[ "${JOB_ERROR}" != "" ]]; then
#   echo "Job failed with error: ${JOB_ERROR}"
#   cat lily.log
#   exit 1
# fi

# lily stop

# # Check there are no errors on visor_processing_reports.csv
# if grep -q "ERROR" /tmp/data/*visor_processing_reports.csv; then
#   echo "Errors found on visor_processing_reports!"
#   cat /tmp/data/*visor_processing_reports.csv | grep "ERROR"
#   exit 1
# fi

# # Check the chain_consensus file has WALK_EPOCHS + 1 (header) lines
# if [[ $(wc -l < /tmp/data/*chain_consensus.csv) -ne $((WALK_EPOCHS + 1)) ]]; then
#   echo "chain_consensus file has $(wc -l < /tmp/data/*chain_consensus.csv) lines, expected $((WALK_EPOCHS + 2))"
#   exit 1
# fi

# # Compress the CSV files
# gzip /tmp/data/*.csv

# # Move files to export dir
# echo "Saving CSV files to ${EXPORT_DIR}"
# FILENAME=$(basename "${SNAPSHOT_FILE}" .car.zst)
# if [ -d "${EXPORT_DIR:?}"/"${FILENAME:?}"/ ]; then rm -Rf "${EXPORT_DIR:?}"/"${FILENAME:?}"/; fi
# mkdir -p "$EXPORT_DIR"/"$FILENAME"/
# mv /tmp/data/*.csv.gz "$EXPORT_DIR"/"$FILENAME"/
# mv lily.log "$EXPORT_DIR"/"$FILENAME"/
