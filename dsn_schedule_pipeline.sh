#!/bin/bash

# Fail on any error.
set -eo pipefail

# Create the folder if it doesn't already exist.
mkdir -p $BASE/data/dsn-schedule

# Launch the pipeline.
$BASE/code/dsn-schedule-pipeline/run.sh `date -u +%FT%H` $BASE/data/dsn-schedule

# Sync the folder to AWS.
$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-dev/assets/dynamic/dsn-schedule $BASE/data/dsn-schedule quiet
$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-staging/assets/dynamic/dsn-schedule $BASE/data/dsn-schedule quiet
$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-production/assets/dynamic/dsn-schedule $BASE/data/dsn-schedule quiet
