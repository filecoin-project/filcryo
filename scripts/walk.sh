#!/usr/bin/env bash
#
# Usage: ./walk.sh [SNAPSHOT_URL]
# Defaults to the latest snapshot available.

set -eo pipefail

curl -w "%{url_effective}\n" -I -L -s -S https://snapshots.mainnet.filops.net/minimal/latest -o /dev/null

SNAPSHOT_URL="${1:-"https://snapshots.mainnet.filops.net/minimal/latest"}"
REPO_PATH="${REPO_PATH:-"/var/lib/lily"}"

echo "Initializing Lily repository with ${SNAPSHOT_URL}"

export GOLOG_LOG_FMT=json

aria2c -x16 -s16 "${SNAPSHOT_URL}" -o /tmp/snapshot.car

lily init --config /lily/config.toml --repo ${REPO_PATH} --import-snapshot /tmp/snapshot.car

nohup lily daemon --repo=${REPO_PATH} --config /lily/config.toml &> out.log &

lily wait-api

STATE=$(lily chain state-inspect -l 4000)
FROM_EPOCH=$(echo $STATE | jq -r ".summary.messages.oldest")
TO_EPOCH=$(($FROM_EPOCH + 2000))

echo "Walking from epoch ${FROM_EPOCH} to ${TO_EPOCH}"

sleep 10

lily job run --storage=CSV walk --from ${FROM_EPOCH} --to ${TO_EPOCH}

lily job wait --id 1

lily stop

lily job list

ls -lh /data
