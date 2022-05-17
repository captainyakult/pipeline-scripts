#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Run the dynamogen.
$BASE/code/dynamogen/dynamogen.sh --verbose --spice $BASE/data/spice --output $BASE/data/dynamo --config $BASE/code/dynamogen/config/$1.json
