#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Sync the spice.
$BASE/code/spice-syncer/sync.sh -d $BASE/data/spice -b $1 
