#!/bin/bash

set -euo pipefail

. filcryo.sh

compress_snapshot "$1"
