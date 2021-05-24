#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
TLE_SYNCER_DIR=$BASE/pipelines/tle_syncer
TLE_TO_SPK_DIR=$BASE/pipelines/tle_to_spk
AWS_S3_SYNC_DIR=$BASE/pipelines/aws-s3-sync
TLE_DIR=$BASE/sources/tle
CLOUDFRONT_PRODUCTION_ID=E3JMG193HISS1S

# Get the needed lsk file.
lsk_file=$(ls $BASE/sources/spice/lsk/00_lsk/naif* | tail -n1)

echo "Updating TLEs..."

# Sync the TLEs.
$TLE_SYNCER_DIR/sync.py -o $TLE_DIR/merged_new.txt

# Compare the results to the backup and generated a list of spacecraft to generate.
tle_list=$($TLE_SYNCER_DIR/compare.py $TLE_DIR/merged.txt $TLE_DIR/merged_new.txt | sort)

IFS=$'\n'
for tle_name in $tle_list; do
	if [ $tle_name == '' ]; then break; fi
	pioneer_name=$(echo "$tle_name" | $TLE_SYNCER_DIR/names_to_eyes.py)
	echo "  Updating $tle_name/$pioneer_name..."
	# Create the spk.
	echo "    tle -> spk"
	mkdir -p $BASE/sources/spice/$pioneer_name
	$TLE_TO_SPK_DIR/tle_to_spk.py -t $TLE_DIR/merged_new.txt -n "$tle_name" -l $lsk_file -o $BASE/sources/spice/$pioneer_name/out.bsp -s 0 -e 2419200
	# Create the filename for the spk.
	DATE=`brief $BASE/sources/spice/$pioneer_name/out.bsp | grep "^[ ]*[0-9][0-9][0-9][0-9]" | awk -F '[[:space:]][[:space:]]+' '{ print $2 }'`
	if [ `uname -s` == 'Darwin' ]; then
		DATE=`date -j -f "%Y %b %d %H:%M:%S" "$DATE" "+%Y%m%d_%H%M%S" 2> /dev/null`
	else
		DATE=`chronos -FROM UTC -TO UTC -TIME "$DATE" -SETUP $lsk_file`
		DATE=`date -d "$DATE" "+%Y%m%d_%H%M%S" 2> /dev/null`
	fi
	mv $BASE/sources/spice/$pioneer_name/out.bsp $BASE/sources/spice/$pioneer_name/$DATE.bsp
	# Create the animdata.
	echo "    spk -> animdata"
	$BASE/pipelines/animdatagen/animdatagen --spice $BASE/sources/spice --output $BASE/sources/animdata --config $BASE/pipelines/animdatagen/config/tles/$pioneer_name.json
	# Create the dynamo.
	echo "    spk -> dynamo"
	$BASE/pipelines/dynamogen/dynamogen --spice $BASE/sources/spice --output $BASE/sources/dynamo --config $BASE/pipelines/dynamogen/config/tles/$pioneer_name.json
	echo "    Uploading animdata"
	# Upload animdata to blackhawk2 and AWS
	ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/master/spice/$pioneer_name/"
	scp -r -p -q $BASE/sources/animdata/$pioneer_name/* pipeline@blackhawk2:/var/server/master/spice/$pioneer_name/
	ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/staging/spice/$pioneer_name/"
	scp -r -p -q $BASE/sources/animdata/$pioneer_name/* pipeline@blackhawk2:/var/server/staging/spice/$pioneer_name/
	$AWS_S3_SYNC_DIR/sync.py upload-folder eyesstage/server/spice/$pioneer_name $BASE/sources/animdata/$pioneer_name quiet
	ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/production/spice/$pioneer_name/"
	scp -r -p -q $BASE/sources/animdata/$pioneer_name/* pipeline@blackhawk2:/var/server/production/spice/$pioneer_name/
	$AWS_S3_SYNC_DIR/sync.py upload-folder eyesstatic/server/spice/$pioneer_name $BASE/sources/animdata/$pioneer_name quiet
	$AWS_S3_SYNC_DIR/invalidate.py $CLOUDFRONT_PRODUCTION_ID "/server/spice/"$pioneer_name"/*"
	# Upload dynamo to AWS
	echo "    Uploading dynamo"
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-dev/assets/dynamic/dynamo/$pioneer_name $BASE/sources/dynamo/$pioneer_name quiet
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-staging/assets/dynamic/dynamo/$pioneer_name $BASE/sources/dynamo/$pioneer_name quiet
	$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-production/assets/dynamic/dynamo/$pioneer_name $BASE/sources/dynamo/$pioneer_name quiet
	$AWS_S3_SYNC_DIR/invalidate.py $CLOUDFRONT_PRODUCTION_ID "/assets/dynamic/dynamo/$pioneer_name/*"
done

# Copy the new merged.txt to the main one.
mv $TLE_DIR/merged_new.txt $TLE_DIR/merged.txt

# Copy tle_syncer/names.txt to the folder.
cp --preserve=timestamps $TLE_SYNCER_DIR/names.txt $TLE_DIR

# Upload the TLE list files to AWS.
echo "Uploading TLE list files to AWS."
$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-dev/assets/dynamic/tle $TLE_DIR quiet
$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-staging/assets/dynamic/tle $TLE_DIR quiet
$AWS_S3_SYNC_DIR/sync.py sync-s3-folder eyes-production/assets/dynamic/tle $TLE_DIR quiet
$AWS_S3_SYNC_DIR/invalidate.py $CLOUDFRONT_PRODUCTION_ID "/assets/dynamic/tle/*"

echo "Complete"
