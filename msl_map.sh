#!/bin/bash

set -e

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

pushd $BASE/pipelines/msl_ground_map/ > /dev/null
$BASE/pipelines/msl_ground_map/msl_ground_map.py $BASE/sources/marsMap/ | $BASE/pipelines/logger/log.sh >> $BASE/logs/msl_ground_map.log 2>&1
popd > /dev/null

# copy to blackhawk2 (dev)
scp -r -p -q $BASE/sources/marsMap/* pipeline@blackhawk2:/var/server/master/data/marsMap/
# copy to aws s3
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyesstage/server/data/marsMap $BASE/sources/marsMap >> $BASE/logs/aws_s3_sync.log 2>&1
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyesstatic/server/data/marsMap $BASE/sources/marsMap >> $BASE/logs/aws_s3_sync.log 2>&1
