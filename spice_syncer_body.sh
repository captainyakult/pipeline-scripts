#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Sync the spice.
$BASE/pipelines/spice_syncer/sync.py -d $BASE/sources/spice -b $1 
