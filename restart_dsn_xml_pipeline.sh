#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
LOGS=$BASE/logs
cd $BASE/pipelines/dsn-xml-pipeline
$BASE/pipelines/dsn-xml-pipeline/restart.sh &> $LOGS/dsn_xml_pipeline.log
