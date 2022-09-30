#!/usr/bin/env bash
#
# Usage: ./walk.sh [SNAPSHOT_URL]
# Defaults to the latest snapshot available.

set -eox pipefail

SNAPSHOT_URL="${1:-"https://snapshots.mainnet.filops.net/minimal/latest"}"
REPO_PATH="${REPO_PATH:-"/var/lib/lily"}"

echo "Initializing Lily repository with ${SNAPSHOT_URL}"

aria2c -x16 -s16 "${SNAPSHOT_URL}" -d /tmp

export GOLOG_LOG_FMT=json

lily init --config /lily/config.toml --repo "${REPO_PATH}" --import-snapshot /tmp/*.car
nohup lily daemon --repo="${REPO_PATH}" --config=/lily/config.toml --bootstrap=false &> out.log &

lily wait-api

CAR_FILE_NAME=$(find /tmp/*.car -maxdepth 1 -print0 | xargs -0 -n1 basename)
TO_EPOCH=${CAR_FILE_NAME%%_*}
FROM_EPOCH=$((TO_EPOCH - 2000))

echo "Walking from epoch ${FROM_EPOCH} to ${TO_EPOCH}"

sleep 10

lily job run --storage=CSV walk --from "${FROM_EPOCH}" --to "${TO_EPOCH}"

lily job wait --id 1

lily stop

ls -lh /tmp/data

mkdir -p /gcs/"$CAR_FILE_NAME"
mv /tmp/data/*.csv /gcs/"$CAR_FILE_NAME/"
