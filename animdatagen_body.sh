#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Run the animdatagen.
$BASE/pipelines/animdatagen/animdatagen --verbose --spice $BASE/sources/spice --output $BASE/sources/animdata --config $BASE/pipelines/animdatagen/config/$1.json
