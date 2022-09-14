#!/usr/bin/env bash
#
# Usage: ./walk.sh [SNAPSHOT_URL]
# Defaults to the latest snapshot available.

set -eo pipefail

SNAPSHOT_URL="${1:-"https://snapshots.mainnet.filops.net/minimal/latest"}"
REPO_PATH="${REPO_PATH:-"/lily/.lily"}"

echo "Initializing Lily repository with ${SNAPSHOT_URL}"

GOLOG_LOG_FMT=json \
GOLOG_FILE=/lily/log.json
GOLOG_OUTPUT=file

aria2c -x16 -s16 "${SNAPSHOT_URL}" -o /tmp/snapshot.car

lily init --config /lily/config.toml --repo ${REPO_PATH} --import-snapshot /tmp/snapshot.car

nohup lily daemon --repo=${REPO_PATH} --config /lily/config.toml --blockstore-cache-size 5000000 --statestore-cache-size 3000000 &> out.log &

lily wait-api

STATE=$(lily chain state-inspect -l 4000)
FROM_EPOCH=$(echo $STATE | jq -r ".summary.messages.oldest")
TO_EPOCH=$(echo $STATE | jq -r ".summary.messages.newest")

lily job run --storage=CSV walk --from ${FROM_EPOCH} --to ${TO_EPOCH}

lily job wait --id 1

lily stop

ls -lh /tmp/data
