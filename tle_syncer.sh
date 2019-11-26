#! /bin/bash

# fail on any error
set -e

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# tle downloader
pushd $BASE/pipelines/tle_syncer > /dev/null
$BASE/pipelines/tle_syncer/sync.py -u $BASE/pipelines/scripts/configs/tle_urls.txt -n $BASE/pipelines/scripts/configs/tle_names.txt -o $BASE/sources/tle/merged.txt >> $BASE/logs/tle_syncer.log 2>&1
popd > /dev/null

# copy aws s3
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/tle $BASE/sources/tle >> $BASE/logs/aws_s3_sync.log 2>&1
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/tle $BASE/sources/tle >> $BASE/logs/aws_s3_sync.log 2>&1
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-production/assets/dynamic/tle $BASE/sources/tle >> $BASE/logs/aws_s3_sync.log 2>&1
$BASE/pipelines/aws_s3_sync/invalidate.py E3JMG193HISS1S "/assets/dynamic/tle/*" >> $BASE/logs/aws_s3_sync.log 2>&1
