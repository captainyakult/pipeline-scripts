#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# make sure the library path is set correctly
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/gcc-4.9.0/lib64

# make sure the output folder exists
mkdir -p $BASE/pipelines/dsn-now-map-gen/output

# create the map files
pushd $BASE/pipelines/dsn-now-map-gen > /dev/null
./updatemap
popd > /dev/null

# copy aws s3 (no logging since it happens so often)
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/dsn-now-map $BASE/pipelines/dsn-now-map-gen/output
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/dsn-now-map $BASE/pipelines/dsn-now-map-gen/output
$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-production/assets/dynamic/dsn-now-map $BASE/pipelines/dsn-now-map-gen/output


