#!/bin/bash

# fail on any error
set -e

if [ "$#" -ne 2 ]; then
	echo "Syntax is: ./full_sync_dynamo.sh <dev|staging|production> <body>"
	exit -1
fi

$HOME/pipelines/aws_s3_sync/sync.py update-manifest eyes-$1/assets/dynamic/dynamo/$2
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-$1/assets/dynamic/dynamo/$2 $HOME/sources/dynamo/$2

if [ "$1" == "production" ]; then
	$HOME/pipelines/aws_s3_sync/invalidate.py E3JMG193HISS1S "/assets/dynamic/dynamo/"$2"/*"
fi
