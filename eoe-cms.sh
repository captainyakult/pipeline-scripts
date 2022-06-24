#!/bin/bash

# Fail on any error.
set -eo pipefail

SSL_KEY_FOLDER=$BASE/data/keys/ssl
EARTH_EVENTS_FOLDER=$BASE/data/earth_events

# Create the folders if they don't exist.
mkdir -p $EARTH_EVENTS_FOLDER/media
mkdir -p $EARTH_EVENTS_FOLDER/preview
mkdir -p $EARTH_EVENTS_FOLDER/publish

# Check that the server.crt and server.key files exist.
if [[ ! -f "$SSL_KEY_FOLDER/server.crt" || ! -f "$SSL_KEY_FOLDER/server.key" ]]; then
  echo "Make sure you have $SSL_KEY_FOLDER/server.crt and $SSL_KEY_FOLDER/server.key."
	exit 1
fi

# Set initial modified time of publish/touch
touch $EARTH_EVENTS_FOLDER/publish/touch
LTIME=`stat -c %Z $EARTH_EVENTS_FOLDER/publish/touch`

# Start the eoe-cms pipeline in detached mode.
$BASE/code/eoe-cms/run.sh production 3001 $SSL_KEY_FOLDER $EARTH_EVENTS_FOLDER https://blackhawk3.jpl.nasa.gov/assets/dynamic/earth_events/preview &

# Monitor for changes in the modified time of the publish/touch file.
while true; do

  # If the modified time is different, start the AWS sync.
	ATIME=`stat -c %Z $EARTH_EVENTS_FOLDER/publish/touch`
	if [[ "$ATIME" != "$LTIME" ]]; then

    # Sync to staging (old).
    $BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyesstage/server/data/eo $EARTH_EVENTS_FOLDER/publish/eo

    # Sync to production (old).
    $BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyesstatic/server/data/eo $EARTH_EVENTS_FOLDER/publish/eo
    $BASE/code/aws-s3-sync/invalidate.sh E3JMG193HISS1S /server/data/eo

    # Sync to dev, staging, and production.
    $BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-dev/assets/dynamic/earth_events/ $EARTH_EVENTS_FOLDER/publish/eo
    $BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-staging/assets/dynamic/earth_events/ $EARTH_EVENTS_FOLDER/publish/eo
    $BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-production/assets/dynamic/earth_events/ $EARTH_EVENTS_FOLDER/publish/eo
    $BASE/code/aws-s3-sync/invalidate.sh E3JMG193HISS1S /assets/dynamic/earth_events

		LTIME=$ATIME
	fi

  # Wait a bit to check again.
	sleep 10
done

