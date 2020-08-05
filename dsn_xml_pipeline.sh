#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Clear the existing log.
# rm -f $BASE/logs/dxn_xml_pipeline.log

# Launch the pipeline.
cd $BASE/pipelines/dsn-xml-pipeline
$BASE/pipelines/dsn-xml-pipeline/restart.sh
