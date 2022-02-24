#!/bin/bash

# Fail on any error.
set -eo pipefail

# Verify params.
if [ "$#" -lt 1 ]; then
	echo "Syntax is: ./wmts_to_cmts.sh <config name> [YYYY-MM-DD]"
	exit -1
fi

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Get the formatted date.
if [ "$#" -lt 2 ]; then
	TODAY=$(date +'%F')
else
	TODAY=$2
fi

# Make a unique folder.
WMTS_TO_CMTS_DIR=$BASE/temp/$RANDOM

# Run wmts-to-cmts
cd $BASE/code/wmts-to-cmts
./wmts-to-cmts.sh \
	--dim "Time=$TODAY" \
	--input configs/$1.json \
	--output $WMTS_TO_CMTS_DIR

# Run cmts-creator.
cd $BASE/code/cmts-creator
./cmts-creator.sh \
	--input $WMTS_TO_CMTS_DIR/configuration.json \
	--output $BASE/data/cmts/wmts/$1/$TODAY

rm -r $WMTS_TO_CMTS_DIR

# # Copy to AWS S3.
# $AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyesstage/server/data/marsPhoto $MARS_PHOTO_DIR quiet
# $AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyesstatic/server/data/marsPhoto $MARS_PHOTO_DIR quiet

