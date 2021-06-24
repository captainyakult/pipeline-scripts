#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Launch the pipeline.
cd $BASE/pipelines/asteroids-pipeline
python3 sync.py

# Create the folder if it doesn't already exist.
mkdir -p $BASE/sources/asteroids

# Move the generated files to the sources folder.
mv neos.* $BASE/sources/asteroids/
mv closest_approaches.*.json $BASE/sources/asteroids/

# Sync the folder to AWS.
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/asteroids $BASE/sources/asteroids quiet
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/asteroids $BASE/sources/asteroids quiet
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-production/assets/dynamic/asteroids $BASE/sources/asteroids quiet
$BASE/pipelines/aws-s3-sync/invalidate.py E3JMG193HISS1S "/assets/dynamic/asteroids/*"
