#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
EXO_PIPELINE_DIR=$BASE/code/exo-pipeline
AWS_S3_SYNC_DIR=$BASE/code/aws-s3-sync
EXO_DIR=$BASE/data/exo-dev
AWS_URL=https://eyes.nasa.gov/pipeline/exo

# If production, use some different vars.
if [[ ($1 == 'production') ]]; then
		EXO_DIR=$BASE/data/exo
fi

# Create the output directory.
mkdir -p $EXO_DIR

# Run the exo generator.
$EXO_PIPELINE_DIR/run.sh $EXO_DIR/ $AWS_URL

# Upload the files to AWS.
if [[ ($1 == 'production') ]]; then
	$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-production/assets/dynamic/exo/db $EXO_DIR
	$AWS_S3_SYNC_DIR/invalidate.sh E3JMG193HISS1S /assets/dynamic/exo/db
else
	$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-dev/assets/dynamic/exo/db $EXO_DIR
	$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-staging/assets/dynamic/exo/db $EXO_DIR
fi
