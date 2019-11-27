#!/bin/bash

set -e

PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

pushd $BASE/pipelines/msl_photo_fetch/ > /dev/null
$BASE/pipelines/msl_photo_fetch/msl_photo_fetch.py $BASE/sources/marsPhoto/ | $BASE/pipelines/logger/log.sh >> $BASE/logs/msl_photo_fetch.log 2>&1
popd > /dev/null

# copy to blackhawk2 (dev)
scp -r -p -q $BASE/sources/marsPhoto/* pipeline@blackhawk2:/var/server/master/data/marsPhoto/
# copy to aws s3
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyesstage/server/data/marsPhoto $BASE/sources/marsPhoto >> $BASE/logs/aws_s3_sync.log 2>&1
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyesstatic/server/data/marsPhoto $BASE/sources/marsPhoto >> $BASE/logs/aws_s3_sync.log 2>&1
