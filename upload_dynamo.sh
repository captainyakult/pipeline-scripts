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
	$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-dev/assets/dynamic/dynamo/$1 $BASE/data/dynamo/$1
elif [ "$2" == "staging" ]; then
	$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-staging/assets/dynamic/dynamo/$1 $BASE/data/dynamo/$1
elif [ "$2" == "production" ]; then
	$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-production/assets/dynamic/dynamo/$1 $BASE/data/dynamo/$1
	$BASE/code/aws-s3-sync/invalidate.sh E3JMG193HISS1S "/assets/dynamic/dynamo/"$1"/*"
else
	echo "Syntax is: ./upload_dynamo.sh <body> <dev|staging|production>"
fi
