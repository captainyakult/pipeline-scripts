#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
MSL_PHOTO_FETCH_DIR=$BASE/pipelines/msl_photo_fetch
AWS_S3_SYNC_DIR=$BASE/pipelines/aws_s3_sync
LOGGER_DIR=$BASE/pipelines/logger
MARS_PHOTO_DIR=$BASE/sources/marsPhoto
LOGS=$BASE/logs

{
	# Run msl_photo_fetch.
	mkdir -p $MARS_PHOTO_DIR
	$MSL_PHOTO_FETCH_DIR/msl_photo_fetch.py $MARS_PHOTO_DIR/

	# Copy to blackhawk2 (dev).
	scp -r -p -q $MARS_PHOTO_DIR/* pipeline@blackhawk2:/var/server/master/data/marsPhoto/

	# Copy to AWS S3.
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyesstage/server/data/marsPhoto $MARS_PHOTO_DIR
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyesstatic/server/data/marsPhoto $MARS_PHOTO_DIR
} 2>&1 | $LOGGER_DIR/log.sh $LOGS/msl_photo.log
