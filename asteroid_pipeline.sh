#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Launch the pipeline.
cd $BASE/pipelines/asteroids-pipeline
python3 sync.py -v -o $BASE/sources/asteroids -os $BASE/sources/spice

# For every new spk, generate dynamo.
while read F; do
        IFS=',' read -ra ITEMS <<< "$F"
		# Get the item info.
		PIONEER_NAME=${ITEMS[0]}
		NAIF_ID=${ITEMS[1]}
		echo "Generating dynamo for $PIONEER_NAME..."
		# Create the dynamo config.
		cat > $BASE/sources/asteroids/$PIONEER_NAME.sun.orb.json <<- EOM
		{
			"type" : "orb",
			"body" : $NAIF_ID,
			"otherBody" : 10,
			"spiceDirs" : [
				"lsk",
				"celestial",
				"$PIONEER_NAME"
			],
			"limitedCoverage" : [null, null]
		}
		EOM
		# Run dynamo.
		$BASE/pipelines/dynamogen/dynamogen --spice $BASE/sources/spice --output $BASE/sources/dynamo --config $BASE/sources/asteroids/$PIONEER_NAME.sun.orb.json
		# Sync the dynamo folder to AWS.
		$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/dynamo/$PIONEER_NAME $BASE/sources/dynamo/$PIONEER_NAME quiet
		$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/dynamo/$PIONEER_NAME $BASE/sources/dynamo/$PIONEER_NAME quiet
		$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-production/assets/dynamic/dynamo/$PIONEER_NAME $BASE/sources/dynamo/$PIONEER_NAME quiet
		$BASE/pipelines/aws-s3-sync/invalidate.py E3JMG193HISS1S "/assets/dynamic/dynamo/$PIONEER_NAME/*"
done < $BASE/sources/asteroids/newly_generated_spks.txt

# Sync the folder to AWS.
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-dev/assets/dynamic/asteroids $BASE/sources/asteroids quiet
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-staging/assets/dynamic/asteroids $BASE/sources/asteroids quiet
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-production/assets/dynamic/asteroids $BASE/sources/asteroids quiet
$BASE/pipelines/aws-s3-sync/invalidate.py E3JMG193HISS1S "/assets/dynamic/asteroids/*"
