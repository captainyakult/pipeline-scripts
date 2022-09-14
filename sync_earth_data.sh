#!/bin/bash

set -e

do_sync () {
				FROM=$1
				PROJECT=$2
				DATASET=$3
				EYES_FOLDER=$4
				MODE=$5

				# Get the base folder of the system.
				BASE=$(cd "$(dirname "$0")/../.."; pwd)
				DIR=$BASE'/data/earth_data'
				AWS_S3_SYNC_DIR=$BASE/code/aws-s3-sync

				if [ $1 = "esc_imaging_1a" ]; then
					SERVER_PATH=pipeline@esc-imaging-1a:/Volumes/esc/proj/$PROJECT/img/EyesData/$DATASET/
				elif [ $1 = "esc_imaging_2a" ]; then
					SERVER_PATH=pipeline@esc-imaging-2a:/Volumes/esc/proj/$PROJECT/img/EyesData/$DATASET/
				elif [ $1 = "esc_imaging_3a" ]; then
					SERVER_PATH=pipeline@esc-imaging-3a:/Volumes/esc/proj/$PROJECT/img/EyesData/$DATASET/
				fi

				rsync -avL --size-only --delete-before --delete-excluded --delete -f'+ /[1-9][0-9]/' -f'+ /[1-9][0-9]/[0-9][0-9][0-9][0-9]_[0-6].png' -f'+ /[1-9][0-9]/[0-9][0-9][0-9][0-9]_cyl.png' -f'+ /[1-9][0-9]/[0-9][0-9][0-9][0-9]_7.unity3d' -f'- **' $SERVER_PATH $DIR/$EYES_FOLDER

				echo

				python3 $BASE/code/scripts/create_data_inventory.py $DIR/$EYES_FOLDER $MODE

				# Upload the files to AWS.
				$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyesstage/server/data/$EYES_FOLDER $DIR/$EYES_FOLDER
				echo $AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyesstatic/server/data/$EYES_FOLDER $DIR/$EYES_FOLDER
}

do_sync esc_imaging_1a airs/airs_tot airsTotDay newVaporColToday daily 
