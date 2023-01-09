#!/bin/bash

set -euxo pipefail

. filcryo.sh

while true; do
    start=$(get_last_epoch)
    wait_for_epoch "${start}"
    export_range "${start}"
    compress_snapshot "${start}"
    upload_snapshot "${start}"
    sleep 10
done
