#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

AWS_S3_SYNC=$BASE/pipelines/aws-s3-sync
SPICE=$BASE/sources/spice
ANIMDATA=$BASE/sources/animdata
DYNAMO=$BASE/sources/dynamo
CLOUDFRONT_PRODUCTION_ID=E3JMG193HISS1S
LOGS=$BASE/logs
LOCK_FOLDER=/tmp/update_spice.lock

# Function to remove the lock folder.
function clean_lock {
	if !(rmdir $LOCK_FOLDER); then
		exit 1
	fi
}

# Return if it is already running.
if !(mkdir $LOCK_FOLDER); then
	exit 0
fi
trap "clean_lock" EXIT

# make sure the library path is set correctly
# make sure the path and library path is set correctly
export PATH=/usr/local/gcc-4.9.0/bin:$BASE/pipelines/animdatagen/cspice/exe:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/gcc-4.9.0/lib64

# Run spice-syncer.
echo "  Running spice-syncer..."
$BASE/pipelines/spice-syncer/sync.py -d $SPICE -u $LOGS/spice_syncer_updated_spice.log

# Run animdatagen.
echo "  Running animdatagen..."
pushd $BASE/pipelines/animdatagen > /dev/null
$BASE/pipelines/animdatagen/animdatagen --update --spice $SPICE --output $ANIMDATA --list $LOGS/spice_syncer_updated_spice.log --updatedAnimdataFile $LOGS/animdatagen_updated_animdata.log | sed 's/^/    /'
popd > /dev/null

# Run dynamogen.
echo "  Running dynamogen..."
pushd $BASE/pipelines/dynamogen > /dev/null
$BASE/pipelines/dynamogen/dynamogen --update --spice $SPICE --output $DYNAMO --list $LOGS/spice_syncer_updated_spice.log --updatedFile $LOGS/dynamogen_updated_dynamo.log | sed 's/^/    /'
popd > /dev/null
rm -f $LOGS/spice_syncer_updated_spice.log

# Copy animdata to blackhawk and sync to aws s3.
echo "  Uploading to animdata to blackhawk2 and S3..."
while read folder
do
	echo "    $folder"
	echo "      dev"
	ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/master/spice/$folder/"
	scp -r -p -q $ANIMDATA/$folder/* pipeline@blackhawk2:/var/server/master/spice/$folder/
	echo "      staging"
	ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/staging/spice/$folder/"
	scp -r -p -q $ANIMDATA/$folder/* pipeline@blackhawk2:/var/server/staging/spice/$folder/
	$AWS_S3_SYNC/sync.py upload-folder eyesstage/server/spice/$folder $ANIMDATA/$folder quiet
	echo "      production"
	ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/production/spice/$folder/"
	scp -r -p -q $ANIMDATA/$folder/* pipeline@blackhawk2:/var/server/production/spice/$folder/
	$AWS_S3_SYNC/sync.py upload-folder eyesstatic/server/spice/$folder $ANIMDATA/$folder quiet
	$AWS_S3_SYNC/invalidate.py $CLOUDFRONT_PRODUCTION_ID "/server/spice/"$folder"/*"
done < $LOGS/animdatagen_updated_animdata.log
rm -f $LOGS/animdatagen_updated_animdata.log

# sync dynamo to aws s3
echo "  Uploading dynamo to S3..."
while read folder
do
	folder=`echo $folder | cut -d/ -f1`
	echo "    $folder"
	echo "      dev"
	$AWS_S3_SYNC/sync.py sync-s3-folder eyes-dev/assets/dynamic/dynamo/$folder $DYNAMO/$folder quiet
	echo "      staging"
	$AWS_S3_SYNC/sync.py sync-s3-folder eyes-staging/assets/dynamic/dynamo/$folder $DYNAMO/$folder quiet
	echo "      production"
	$AWS_S3_SYNC/sync.py sync-s3-folder eyes-production/assets/dynamic/dynamo/$folder $DYNAMO/$folder quiet
	$AWS_S3_SYNC/invalidate.py $CLOUDFRONT_PRODUCTION_ID "/assets/dynamic/dynamo/"$folder"/*"
done < $LOGS/dynamogen_updated_dynamo.log
rm -f $LOGS/dynamogen_updated_dynamo.log
