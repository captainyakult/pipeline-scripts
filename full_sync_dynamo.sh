#!/bin/bash

# fail on any error
set -e

BASE=$(cd "$(dirname "$0")/../.."; pwd)

if [ "$#" -ne 2 ]; then
	echo "Syntax is: ./full_sync_dynamo.sh <dev|staging|production> <body>"
	exit -1
fi

$BASE/pipelines/aws-s3-sync/sync.py update-manifest eyes-$1/assets/dynamic/dynamo/$2
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-$1/assets/dynamic/dynamo/$2 $BASE/sources/dynamo/$2

if [ "$1" == "production" ]; then
	$BASE/pipelines/aws-s3-sync/invalidate.py E3JMG193HISS1S "/assets/dynamic/dynamo/"$2"/*"
fi
