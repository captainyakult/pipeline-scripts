
#!/bin/bash

# Fail on any error.
set -eo pipefail

API='https://climate-4.client.mooreboeck.com'

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)
DIR=$BASE'/sources/earth-api-dev'
AWS_S3_SYNC_DIR=$BASE/pipelines/aws-s3-sync
DIST='eyes-dev/assets/dynamic/earth/api'
CLOUDFRONT_PRODUCTION_ID=E3JMG193HISS1S

if [[ ($1 == 'production') ]]; then
    DIR=$BASE'/sources/earth-api'
    DIST='eyes-production/assets/dynamic/earth/api'
    API='https://climate.nasa.gov'
fi

VITAL_URL=${API}'/api/v1/earth_now_vital_signs/?category=116'
echo VITAL_URL $VITAL_URL
curl $VITAL_URL > $DIR/vital.json

EVENT_URL=${API}'/api/v1/earth_now_events/?order=date+desc&per_page=-1'
echo EVENT_URL $EVENT_URL
curl $EVENT_URL > $DIR/events.json

MISSION_URL=${API}'/api/v1/missions/?category=133&order=position&per_page=-1'
echo MISSION_URL $MISSION_URL
curl $MISSION_URL > $DIR/mission.json

# Upload the files to AWS.
echo 'syncing ' $DIR ' to ' $DIST
$AWS_S3_SYNC_DIR/sync.py sync-s3-folder $DIST $DIR

if [[ ($1 == 'production') ]]; then
    $AWS_S3_SYNC_DIR/invalidate.py $CLOUDFRONT_PRODUCTION_ID "/assets/dynamic/earth/api/*"
fi