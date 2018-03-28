#! /bin/bash

# tle downloader
pushd $HOME/pipelines/tle_syncer > /dev/null
$HOME/pipelines/tle_syncer/sync.py -d $HOME/sources/tle >> $HOME/logs/tle_syncer.log 2>&1
popd > /dev/null

# copy aws s3
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/tle $HOME/sources/tle >> $HOME/logs/aws_s3_sync.log 2>&1
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/tle $HOME/sources/tle >> $HOME/logs/aws_s3_sync.log 2>&1
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-production/assets/dynamic/tle $HOME/sources/tle >> $HOME/logs/aws_s3_sync.log 2>&1
