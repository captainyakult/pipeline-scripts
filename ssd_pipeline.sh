#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Launch the pipeline. It will also create newly_generated_spks.txt file for creating dynamos.
$BASE/code/ssd-pipeline/sync.sh -v -o $BASE/data/ssd -os $BASE/data/spice/ssd -lsk `ls $BASE/data/spice/lsk/00_lsk/*.tls | tail -n 1`

if [[ -f "$BASE/data/ssd/newly_generated_spks.txt" ]]; then
	# Sort and make unique the newly_generated_spks file since it may have picked up multiple runs before being used and removed.
	sort -u -o $BASE/data/ssd/newly_generated_spks.txt $BASE/data/ssd/newly_generated_spks.txt

	# For every new spk in the newly_generated_spks file, generate dynamo.
	while read F; do
	        IFS=',' read -ra ITEMS <<< "$F"
			# Get the item info.
			PIONEER_NAME=${ITEMS[0]}
			NAIF_ID=${ITEMS[1]}
			CA_TIME=${ITEMS[2]}
			CA_DIST=${ITEMS[3]}
			echo "Generating dynamo for $PIONEER_NAME..."
			# Create the dynamo config.
			cat > $BASE/data/ssd/ssd.$PIONEER_NAME.sun.orb.json <<- EOM
			{
				"type" : "orb",
				"body" : $NAIF_ID,
				"otherBody" : 10,
				"spiceDirs" : [
					"lsk",
					"celestial",
					"ssd/$PIONEER_NAME"
				],
				"limitedCoverage" : [null, null]
			}
			EOM
			# Run dynamo.
			$BASE/code/dynamogen/dynamogen.sh --spice $BASE/data/spice --output $BASE/data/dynamo --config $BASE/data/ssd/ssd.$PIONEER_NAME.sun.orb.json
			rm $BASE/data/ssd/ssd.$PIONEER_NAME.sun.orb.json
			# If the next closest approach distance is less than 0.05 AU, make earth-relative dynamo for that approach as well.
			if (( $(echo "$CA_DIST < 7479893.53455" | bc -l) )); then
				# Do the same for earth.
				echo "Generating Earth-relative dynamo for $PIONEER_NAME..."
				# Get the start and end times.
				START_TIME=$(echo "$CA_TIME - 604800" | bc)
				END_TIME=$(echo "$CA_TIME + 604800" | bc)
				# Create the dynamo config.
				cat > $BASE/data/ssd/ssd.$PIONEER_NAME.earth.orb.json <<- EOM
				{
					"type" : "orb",
					"body" : $NAIF_ID,
					"otherBody" : 399,
					"spiceDirs" : [
						"lsk",
						"celestial",
						"ssd/$PIONEER_NAME"
					],
					"limitedCoverage" : [$START_TIME, $END_TIME]
				}
				EOM
				# Run dynamo.
				$BASE/code/dynamogen/dynamogen.sh --spice $BASE/data/spice --output $BASE/data/dynamo --config $BASE/data/ssd/ssd.$PIONEER_NAME.earth.orb.json
				rm $BASE/data/ssd/ssd.$PIONEER_NAME.earth.orb.json
			fi
			# Sync the dynamo folder to AWS.
			echo "  Uploading to dev, staging, and production AWS..."
			$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-dev/assets/dynamic/dynamo/ssd/$PIONEER_NAME $BASE/data/dynamo/ssd/$PIONEER_NAME quiet
			$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-staging/assets/dynamic/dynamo/ssd/$PIONEER_NAME $BASE/data/dynamo/ssd/$PIONEER_NAME quiet
			$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-production/assets/dynamic/dynamo/ssd/$PIONEER_NAME $BASE/data/dynamo/ssd/$PIONEER_NAME quiet
			$BASE/code/aws-s3-sync/invalidate.sh E3JMG193HISS1S "/assets/dynamic/dynamo/ssd/$PIONEER_NAME/*"
	done < $BASE/data/ssd/newly_generated_spks.txt
fi

# Delete the no longer needed newly_generated_spks file.
rm -f $BASE/data/ssd/newly_generated_spks.txt

# Sync the ssd folder to AWS.
$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-dev/assets/dynamic/ssd $BASE/data/ssd quiet
$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-staging/assets/dynamic/ssd $BASE/data/ssd quiet
$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-production/assets/dynamic/ssd $BASE/data/ssd quiet
$BASE/code/aws-s3-sync/invalidate.sh E3JMG193HISS1S "/assets/dynamic/ssd/*"

