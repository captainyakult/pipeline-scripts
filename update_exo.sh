#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
EXO_PIPELINE_DIR=$BASE/pipelines/exo-pipeline/script
AWS_S3_SYNC_DIR=$BASE/pipelines/aws-s3-sync
EXO_DIR=$BASE/sources/exo

# Create the output directory.
mkdir -p $EXO_DIR

# Updatedatabses.
$EXO_PIPELINE_DIR/updateDatabases.sh https://eyes.nasa.gov/staging/pipeline/exo/

# Run the exo generator.
$EXO_PIPELINE_DIR/generateEoX_Web.sh $EXO_DIR/ https://eyes.nasa.gov/staging/pipeline/exo/

# Upload the files to AWS.
$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-dev/assets/dynamic/exo/db $EXO_DIR
$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-staging/assets/dynamic/exo/db $EXO_DIR
$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-production/assets/dynamic/exo/db $EXO_DIR
