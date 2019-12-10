#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Run the dynamogen.
$BASE/pipelines/dynamogen/dynamogen --verbose --spice $BASE/sources/spice --output $BASE/sources/dynamo --config $BASE/pipelines/dynamogen/config/$1.json
