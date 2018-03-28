#!/bin/bash

# make sure the output folder exists
mkdir -p $HOME/pipelines/dsn-now-map-gen/output

# create the map files
pushd $HOME/pipelines/dsn-now-map-gen > /dev/null
./updatemap
popd > /dev/null

# copy aws s3
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/dsn-now-map $HOME/pipelines/dsn-now-map-gen/output >> $HOME/logs/aws_s3_sync.log 2>&1
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/dsn-now-map $HOME/pipelines/dsn-now-map-gen/output >> $HOME/logs/aws_s3_sync.log 2>&1
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-production/assets/dynamic/dsn-now-map $HOME/pipelines/dsn-now-map-gen/output >> $HOME/logs/aws_s3_sync.log 2>&1


