#!/bin/bash

# fail on any error
set -e

# make sure the library path is set correctly
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/gcc-4.9.0/lib64

# make sure the output folder exists
mkdir -p $HOME/pipelines/dsn-now-map-gen/output

# create the map files
pushd $HOME/pipelines/dsn-now-map-gen > /dev/null
./updatemap
popd > /dev/null

# copy aws s3 (no logging since it happens so often)
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/dsn-now-map $HOME/pipelines/dsn-now-map-gen/output
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/dsn-now-map $HOME/pipelines/dsn-now-map-gen/output
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-production/assets/dynamic/dsn-now-map $HOME/pipelines/dsn-now-map-gen/output


