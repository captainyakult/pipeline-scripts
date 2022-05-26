#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
TLE_SYNCER_DIR=$BASE/code/tle-syncer
TLE_TO_SPK_DIR=$BASE/code/tle-to-spk
AWS_S3_SYNC_DIR=$BASE/code/aws-s3-sync
TLE_DIR=$BASE/data/tle
CLOUDFRONT_PRODUCTION_ID=E3JMG193HISS1S

# Get the needed lsk file.
lsk_file=$(ls $BASE/data/spice/lsk/00_lsk/naif* | tail -n1)

echo "Updating TLEs..."

# Sync the TLEs.
$TLE_SYNCER_DIR/sync.sh -o $TLE_DIR/merged_new.txt

# Compare the results to the backup and generated a list of spacecraft to generate.
tle_list=$($TLE_SYNCER_DIR/compare.sh $TLE_DIR/merged.txt $TLE_DIR/merged_new.txt | sort)

IFS=$'\n'
for tle_name in $tle_list; do
	if [ $tle_name == '' ]; then break; fi
	eyes_name=`$TLE_SYNCER_DIR/tle_name_to_eyes_name.sh "$tle_name"`
	echo "  Updating $tle_name/$eyes_name..."
	if [ -f $BASE/code/animdatagen/config/tles/$eyes_name.json ] || [ -f $BASE/code/dynamogen/config/tles/$eyes_name.json ]; then
		# Create the spk.
		echo "    tle -> spk"
		mkdir -p $BASE/data/spice/$eyes_name
		$TLE_TO_SPK_DIR/tle_to_spk.sh -t $TLE_DIR/merged_new.txt -n "$tle_name" -l $lsk_file -o $BASE/data/spice/$eyes_name/out.bsp -s 0 -e 2419200
		# Create the filename for the spk.
		DATE=`$TLE_TO_SPK_DIR/get_date_of_spk.sh $BASE/data/spice/$eyes_name/out.bsp $lsk_file`
		DATE=`date -d "$DATE" "+%Y%m%d_%H%M%S" 2> /dev/null`
		mv $BASE/data/spice/$eyes_name/out.bsp $BASE/data/spice/$eyes_name/$DATE.bsp
		# Create and upload the animdata.
		if [ -f $BASE/code/animdatagen/config/tles/$eyes_name.json ]; then
			echo "    spk -> animdata"
			$BASE/code/animdatagen/animdatagen.sh --spice $BASE/data/spice --output $BASE/data/animdata --config $BASE/code/animdatagen/config/tles/$eyes_name.json
			echo "    Uploading animdata to bh2"
			ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/master/spice/$eyes_name/"
			scp -r -p -q $BASE/data/animdata/$eyes_name/* pipeline@blackhawk2:/var/server/master/spice/$eyes_name/
			# ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/staging/spice/$eyes_name/"
			# scp -r -p -q $BASE/data/animdata/$eyes_name/* pipeline@blackhawk2:/var/server/staging/spice/$eyes_name/
			# ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/production/spice/$eyes_name/"
			# scp -r -p -q $BASE/data/animdata/$eyes_name/* pipeline@blackhawk2:/var/server/production/spice/$eyes_name/
			echo "    Uploading animdata to AWS"
			# $AWS_S3_SYNC_DIR/sync.sh upload-folder eyesstage/server/spice/$eyes_name $BASE/data/animdata/$eyes_name quiet
			# $AWS_S3_SYNC_DIR/sync.sh upload-folder eyesstatic/server/spice/$eyes_name $BASE/data/animdata/$eyes_name quiet
			# $AWS_S3_SYNC_DIR/invalidate.sh $CLOUDFRONT_PRODUCTION_ID "/server/spice/"$eyes_name"/*"
		fi
		# Create and upload the dynamo.
		if [ -f $BASE/code/dynamogen/config/tles/$eyes_name.json ]; then
			echo "    spk -> dynamo"
			$BASE/code/dynamogen/dynamogen.sh --spice $BASE/data/spice --output $BASE/data/dynamo --config $BASE/code/dynamogen/config/tles/$eyes_name.json
			echo "    Uploading dynamo"
			$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-dev/assets/dynamic/dynamo/$eyes_name $BASE/data/dynamo/$eyes_name quiet
			# $AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-staging/assets/dynamic/dynamo/$eyes_name $BASE/data/dynamo/$eyes_name quiet
			# $AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-production/assets/dynamic/dynamo/$eyes_name $BASE/datas/dynamo/$eyes_name quiet
			# $AWS_S3_SYNC_DIR/invalidate.sh $CLOUDFRONT_PRODUCTION_ID "/assets/dynamic/dynamo/$eyes_name/*"
		fi
	fi
done

# Copy the new merged.txt to the main one.
mv $TLE_DIR/merged_new.txt $TLE_DIR/merged.txt

# Copy tle_syncer/names.txt to the folder.
rsync -rtq $TLE_SYNCER_DIR/names.txt $TLE_DIR

# Upload the TLE list files to AWS.
echo "Uploading TLE list files to AWS."
$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-dev/assets/dynamic/tle $TLE_DIR quiet
# $AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-staging/assets/dynamic/tle $TLE_DIR quiet
# $AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-production/assets/dynamic/tle $TLE_DIR quiet
# $AWS_S3_SYNC_DIR/invalidate.sh $CLOUDFRONT_PRODUCTION_ID "/assets/dynamic/tle/*"

echo "Complete"
