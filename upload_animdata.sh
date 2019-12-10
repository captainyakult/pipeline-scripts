#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

if [ "$#" -ne 2 ]; then
	echo "Syntax is: ./upload_animdata.sh <dev|staging|production> <body>"
	exit -1
fi

if [ "$1" == "dev" ]; then
	#ssh pipeline@blackhawk2 "rm /var/server/master/spice/$2"
	ssh pipeline@blackhawk2 "mkdir -p /var/server/master/spice/$2"
	scp -r -p -q $BASE/sources/animdata/$2/* pipeline@blackhawk2:/var/server/master/spice/$2/
elif [ "$1" == "staging" ]; then
	#ssh pipeline@blackhawk2 "rm /var/server/staging/spice/$2"
	ssh pipeline@blackhawk2 "mkdir -p /var/server/staging/spice/$2"
	scp -r -p -q $BASE/sources/animdata/$2/* pipeline@blackhawk2:/var/server/staging/spice/$2/
	$BASE/pipelines/aws_s3_sync/sync.py upload-folder eyesstage/server/spice/$2 $BASE/sources/animdata/$2
elif [ "$1" == "production" ]; then
	#ssh pipeline@blackhawk2 "rm /var/server/production/spice/$2"
	ssh pipeline@blackhawk2 "mkdir -p /var/server/production/spice/$2"
	scp -r -p -q $BASE/sources/animdata/$2/* pipeline@blackhawk2:/var/server/production/spice/$2/
	$BASE/pipelines/aws_s3_sync/sync.py upload-folder eyesstatic/server/spice/$2 $BASE/sources/animdata/$2
	$BASE/pipelines/aws_s3_sync/invalidate.py E3JMG193HISS1S "/server/spice/"$2"/*"
else
	echo "Syntax is: ./upload_animdata.sh <dev|staging|production> <body>"
fi
