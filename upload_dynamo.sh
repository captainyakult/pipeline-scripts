#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

if [ "$#" -ne 2 ]; then
	echo "Syntax is: ./upload_dynamo.sh <body> <dev|staging|production>"
	exit -1
fi

if [ "$2" == "dev" ]; then
	$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/dynamo/$1 $BASE/sources/dynamo/$1
elif [ "$2" == "staging" ]; then
	$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/dynamo/$1 $BASE/sources/dynamo/$1
elif [ "$2" == "production" ]; then
	$BASE/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-production/assets/dynamic/dynamo/$1 $BASE/sources/dynamo/$1
	$BASE/pipelines/aws_s3_sync/invalidate.py E3JMG193HISS1S "/assets/dynamic/dynamo/"$1"/*"
else
	echo "Syntax is: ./upload_dynamo.sh <body> <dev|staging|production>"
fi
