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
