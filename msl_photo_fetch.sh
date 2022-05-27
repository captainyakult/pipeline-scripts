#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
MSL_PHOTO_FETCH_DIR=$BASE/code/msl-photo-fetch
AWS_S3_SYNC_DIR=$BASE/code/aws-s3-sync
MSL_PHOTO_DIR=$BASE/data/msl_photo

# Run msl_photo_fetch.
mkdir -p $MSL_PHOTO_DIR
$MSL_PHOTO_FETCH_DIR/msl_photo_fetch.sh $MSL_PHOTO_DIR/

# Copy to blackhawk2 (dev).
scp -r -p -q $MSL_PHOTO_DIR/* pipeline@blackhawk2:/var/server/master/data/marsPhoto/

# Copy to AWS S3.
$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyesstage/server/data/marsPhoto $MSL_PHOTO_DIR quiet
$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyesstatic/server/data/marsPhoto $MSL_PHOTO_DIR quiet

