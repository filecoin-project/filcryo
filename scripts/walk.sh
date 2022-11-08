#!/usr/bin/env bash
#
# Usage: ./walk.sh [SNAPSHOT_URL]
# Defaults to the latest snapshot available.

set -eox pipefail

export GOLOG_LOG_FMT=json

SNAPSHOT_URL="${1:-"https://snapshots.mainnet.filops.net/minimal/latest"}"
REPO_PATH="${REPO_PATH:-"/var/lib/lily"}"
WALK_EPOCHS="${WALK_EPOCHS:-"400"}"

echo "Initializing Lily repository with ${SNAPSHOT_URL}"

# Download the snapshot
aria2c -x16 -s16 "${SNAPSHOT_URL}" -d /tmp

# If the snapshot is compressed, extract it.
if [[ "${SNAPSHOT_URL}" == *.zst ]]; then
  unzstd /tmp/*.car.zst
fi

# Start Lily
lily init --config /lily/config.toml --repo "${REPO_PATH}" --import-snapshot /tmp/*.car
nohup lily daemon --repo="${REPO_PATH}" --config=/lily/config.toml --bootstrap=false &> out.log &

# Wait for Lily to come online
lily wait-api

# Extract walk epochs from the snapshot
CAR_FILE_NAME=$(find /tmp/*.car -maxdepth 1 -print0 | xargs -0 -n1 basename)
TO_EPOCH=${CAR_FILE_NAME%%_*}
FROM_EPOCH=$((TO_EPOCH - WALK_EPOCHS))

echo "Walking from epoch ${FROM_EPOCH} to ${TO_EPOCH}"

sleep 10

# Run job
lily job run --storage=CSV walk --from "${FROM_EPOCH}" --to "${TO_EPOCH}"

# Wait for job to finish
lily job wait --id 1 && lily stop

ls -lh /tmp/data

mkdir -p /gcs/"$CAR_FILE_NAME"
mv /tmp/data/*.csv /gcs/"$CAR_FILE_NAME"/
mv out.log /gcs/"$CAR_FILE_NAME"/
