#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

SPICE=$BASE/sources/spice
POSITIONS=$BASE/sources/positions

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/gcc-4.9.0/lib64

# Run position_pipeline.
pushd $BASE/pipelines/position-pipeline > /dev/null
$BASE/pipelines/position-pipeline/position_pipeline -s $SPICE -o $POSITIONS -e place_jpl -r solar_system_barycenter
popd > /dev/null

