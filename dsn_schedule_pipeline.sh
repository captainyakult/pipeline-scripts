#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Create the folder if it doesn't already exist.
mkdir -p $BASE/sources/dsn-schedule

# Launch the pipeline.
cd $BASE/pipelines/dsn-schedule-pipeline
python3 $BASE/pipelines/dsn-schedule-pipeline/run.py `date -u +%FT%H` $BASE/sources/dsn-schedule

# Sync the folder to AWS.
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/dsn-schedule $BASE/sources/dsn-schedule quiet
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/dsn-schedule $BASE/sources/dsn-schedule quiet
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-production/assets/dynamic/dsn-schedule $BASE/sources/dsn-schedule quiet
