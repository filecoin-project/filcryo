#!/bin/bash

set -euxo pipefail

START_EPOCH=$1

# Verify the snapshot exists. Exits with error otherwise.
snapshot_url=`gcloud storage ls "gs://fil-mainnet-archival-snapshots/historical-exports/snapshot_${START_EPOCH}_*_*.car.zst"`
snapshot_name=`basename ${snapshot_url}`

gcloud storage cp "${snapshot_url}" .

zstd --rm -d "${snapshot_name}"

echo "Snapshot downloaded and decompressed successfully"
