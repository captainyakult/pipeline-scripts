#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
MSL_GROUND_MAP_DIR=$BASE/pipelines/msl_ground_map
AWS_S3_SYNC_DIR=$BASE/pipelines/aws_s3_sync
LOGGER_DIR=$BASE/pipelines/logger
MARS_MAP_DIR=$BASE/sources/marsMap
LOGS=$BASE/logs

{
	# Run the msl_ground_map.
	mkdir -p $MARS_MAP_DIR
	$MSL_GROUND_MAP_DIR/msl_ground_map.py $MARS_MAP_DIR/

	# Copy to blackhawk2 (dev).
	scp -r -p -q $MARS_MAP_DIR/* pipeline@blackhawk2:/var/server/master/data/marsMap/

	# Copy to AWS S3.
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyesstage/server/data/marsMap $MARS_MAP_DIR
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyesstatic/server/data/marsMap $MARS_MAP_DIR
} 2>&1 | $LOGGER_DIR/log.sh $LOGS/msl_map.log
