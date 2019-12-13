#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Sync the TLEs.
$BASE/pipelines/tle_syncer/sync.py -u $BASE/pipelines/scripts/configs/tle_urls.txt -n $BASE/pipelines/scripts/configs/tle_names.txt -o $BASE/sources/tle/merged.txt 2>&1 | $BASE/pipelines/logger/log.sh $BASE/logs/update_tles.log

# Upload them to AWS.
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/tle $BASE/sources/tle 2>&1 | $BASE/pipelines/logger/log.sh $BASE/logs/update_tles.log
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/tle $BASE/sources/tle 2>&1 | $BASE/pipelines/logger/log.sh $BASE/logs/update_tles.log
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-production/assets/dynamic/tle $BASE/sources/tle 2>&1 | $BASE/pipelines/logger/log.sh $BASE/logs/update_tles.log
$BASE/pipelines/aws_s3_sync/invalidate.py E3JMG193HISS1S "/assets/dynamic/tle/*" 2>&1 | $BASE/pipelines/logger/log.sh $BASE/logs/update_tles.log
