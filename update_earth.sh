#!/bin/bash

# Fail on any error.
set -eo pipefail

API='https://climate-vtad.client.mooreboeck.com'

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
DIR=$BASE'/data/earth-api-dev'
AWS_S3_SYNC_DIR=$BASE/code/aws-s3-sync
DIST='eyes-dev/assets/dynamic/earth/api'
CLOUDFRONT_PRODUCTION_ID=E3JMG193HISS1S

if [[ ($1 == 'production') ]]; then
    DIR=$BASE'/data/earth-api'
    DIST='eyes-production/assets/dynamic/earth/api'
    API='https://climate.nasa.gov'
fi

echo "Getting Earth Now Vital Signs"
VITAL_URL=${API}'/api/v1/earth_now_vital_signs/?category=116'
curl -sS $VITAL_URL > $DIR/vital.json

echo "Getting Earth Now Events"
EVENT_URL=${API}'/api/v1/earth_now_events/?order=date+desc&per_page=-1'
curl -sS $EVENT_URL > $DIR/events.json

echo "Getting Earth Missions"
MISSION_URL=${API}'/api/v1/missions/?category=133&order=position&per_page=-1'
curl -sS $MISSION_URL > $DIR/mission.json

# Upload the files to AWS.
$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder $DIST $DIR

if [[ ($1 == 'production') ]]; then
    $AWS_S3_SYNC_DIR/invalidate.sh $CLOUDFRONT_PRODUCTION_ID "/assets/dynamic/earth/api/*"
fi

