#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
TLE_SYNCER_DIR=$BASE/code/tle-syncer
TLE_DIR=$BASE/data/tle

echo "Updating local TLEs..."

cp $TLE_SYNCER_DIR/local_tles.txt $TLE_DIR/local_tles.txt
$TLE_SYNCER_DIR/update_local_tles.sh $TLE_DIR/local_tles.txt

echo "Complete"
