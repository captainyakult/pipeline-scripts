#!/bin/bash

# fail on any error
set -e

pushd $HOME/pipelines/dynamogen > /dev/null
./dynamogen --verbose --spice $HOME/sources/spice --output $HOME/sources/dynamo --config config/$1.json
popd > /dev/null
