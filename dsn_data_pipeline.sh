#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Start the dsn data pipeline, if it isn't already running.
if [[ `ps -ef | grep "docker run .* dsn-data-pipeline" | grep -v grep` == "" ]]; then
	echo "Starting pipeline."
	# $BASE/code/dsn-data-pipeline/build.sh
	# $BASE/code/dsn-data-pipeline/run.sh TSTEOTSS $BASE/data/dsn/data clean
	# $BASE/code/dsn-data-pipeline/run.sh TSTEOTSS $BASE/data/dsn/data &
fi

# Create the folders if they don't exist.
mkdir -p $BASE/data/dsn/data
mkdir -p $BASE/data/dsn/data-archive

# Set initial modified time of file
LTIME=`stat -c %Z $BASE/data/dsn/data/dsn.xml`

while true; do
	ATIME=`stat -c %Z $BASE/data/dsn/data/dsn.xml`

	if [[ "$ATIME" != "$LTIME" ]]; then

		# echo "Updating $ATIME"
		echo $ATIME "("`date -d @$ATIME`")" "("`date`")"

		# Copy the data to a temp folder. This prevents race conflicts between uploading the file and the file changing.
		mkdir -p $BASE/temp/dsn-data
		rsync -rtvq $BASE/data/dsn/data/ $BASE/temp/dsn-data/

		# Make an archive file.
		rsync -rtvq $BASE/temp/dsn-data/dsn.xml $BASE/data/dsn/data-archive/$ATIME.xml

		# AWS sync the folder up to S3.
		$BASE/code/aws-s3-sync/sync.sh upload-folder eyes-dev/assets/dynamic/dsn/data $BASE/temp/dsn-data/

		LTIME=$ATIME
	fi
	sleep 1
done

echo $LTIME

# # AWS sync the files up to S3.
# echo "Uploading the built app to the S3 folder."
# $BASE/code/aws-s3-sync/sync.sh upload-s3-folder eyes-dev/assets/dynamic/dsn/data dsn.xml
