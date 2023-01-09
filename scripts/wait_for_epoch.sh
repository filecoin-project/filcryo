#!/bin/bash

set -euo pipefail

. filcryo.sh

wait_for_epoch "$1"
