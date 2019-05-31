#!/bin/bash

# fail on any error
set -e

if [ "$#" -ne 2 ]; then
	echo "Syntax is: ./upload_dynamo.sh <dev|staging|production> <body>"
	exit -1
fi

if [ "$1" == "dev" ]; then
	$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/dynamo/$2 $HOME/sources/dynamo/$2
elif [ "$1" == "staging" ]; then
	$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/dynamo/$2 $HOME/sources/dynamo/$2
elif [ "$1" == "production" ]; then
	$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-production/assets/dynamic/dynamo/$2 $HOME/sources/dynamo/$2
	$HOME/pipelines/aws_s3_sync/invalidate.py E3JMG193HISS1S "/assets/dynamic/dynamo/"$2"*"
else
	echo "Syntax is: ./upload_dynamo.sh <dev|staging|production> <body>"
fi
