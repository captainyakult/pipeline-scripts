#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Make sure the data folder exists.
mkdir -p $BASE/data/dsn-now-map

# Run the pipeline.
$BASE/code/dsn-now-map-gen/run.sh $BASE/data/dsn-now-map

# Sync the data folder to AWS.
$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-dev/assets/dynamic/dsn-now-map $BASE/data/dsn-now-map quiet
$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-staging/assets/dynamic/dsn-now-map $BASE/data/dsn-now-map quiet
$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-production/assets/dynamic/dsn-now-map $BASE/data/dsn-now-map quiet

