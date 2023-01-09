#!/bin/bash

set -euo pipefail

START_EPOCH=$1

export_and_upload () {
    epoch=$1
    ./chain_export_range.sh "${epoch}"
    ./compress_snapshot.sh "${epoch}"
    ./upload_snapshot.sh "${epoch}"
}

start=${START_EPOCH}

for i in $(seq 0 5); do
    (( "start=${START_EPOCH}+2880*${i}" ))
    export_and_upload "${start}" &    
done

wait
