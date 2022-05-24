#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
MSL_GROUND_MAP_DIR=$BASE/code/msl-ground-map
AWS_S3_SYNC_DIR=$BASE/code/aws-s3-sync
MARS_MAP_DIR=$BASE/data/msl_ground_map

# Run the msl_ground_map.
mkdir -p $MARS_MAP_DIR
$MSL_GROUND_MAP_DIR/msl_ground_map.sh $MARS_MAP_DIR/

# Copy to blackhawk2 (dev).
scp -r -p -q $MARS_MAP_DIR/* pipeline@blackhawk2:/var/server/master/data/marsMap/

# Copy to AWS S3.
$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyesstage/server/data/marsMap $MARS_MAP_DIR quiet
$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyesstatic/server/data/marsMap $MARS_MAP_DIR quiet

