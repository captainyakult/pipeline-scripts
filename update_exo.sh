#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
EXO_PIPELINE_DIR=$BASE/pipelines/exo-pipeline-scripts
AWS_S3_SYNC_DIR=$BASE/pipelines/aws_s3_sync
LOGGER_DIR=$BASE/pipelines/logger
EXO_DIR=$BASE/sources/exo
LOGS=$BASE/logs

{
	# Create the output directory.
	mkdir -p $EXO_DIR

	# Run the exo generator.
	$EXO_PIPELINE_DIR/generateEoX_Ranger.sh $EXO_DIR/ http://blackhawk-blade.jpl.nasa.gov:7000/

	# Upload the files to AWS.
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-dev/assets/dynamic/exo/db $EXO_DIR
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-staging/assets/dynamic/exo/db $EXO_DIR
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-production/assets/dynamic/exo/db $EXO_DIR
} 2>&1 | $LOGGER_DIR/log.sh $LOGS/update_exo.log
