#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

if [ "$#" -ne 2 ]; then
	echo "Syntax is: ./upload_animdata.sh <body> <dev|staging|production>"
	exit -1
fi

if [ "$2" == "dev" ]; then
	#ssh pipeline@blackhawk2 "rm /var/server/master/spice/$1"
	ssh pipeline@blackhawk2 "mkdir -p /var/server/master/spice/$1"
	scp -r -p -q $BASE/data/animdata/$1/* pipeline@blackhawk2:/var/server/master/spice/$1/
elif [ "$2" == "staging" ]; then
	#ssh pipeline@blackhawk2 "rm /var/server/staging/spice/$1"
	ssh pipeline@blackhawk2 "mkdir -p /var/server/staging/spice/$1"
	scp -r -p -q $BASE/data/animdata/$1/* pipeline@blackhawk2:/var/server/staging/spice/$1/
	$BASE/code/aws-s3-sync/sync.sh upload-folder eyesstage/server/spice/$1 $BASE/data/animdata/$1
elif [ "$2" == "production" ]; then
	#ssh pipeline@blackhawk2 "rm /var/server/production/spice/$1"
	ssh pipeline@blackhawk2 "mkdir -p /var/server/production/spice/$1"
	scp -r -p -q $BASE/data/animdata/$1/* pipeline@blackhawk2:/var/server/production/spice/$1/
	$BASE/code/aws-s3-sync/sync.sh upload-folder eyesstatic/server/spice/$1 $BASE/data/animdata/$1
	$BASE/code/aws-s3-sync/invalidate.sh E3JMG193HISS1S "/server/spice/"$1"/*"
else
	echo "Syntax is: ./upload_animdata.sh <body> <dev|staging|production>"
fi
