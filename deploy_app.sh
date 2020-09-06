#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

if [[ ($# -ne 3) ]]; then
	echo "usage: deploy_app.sh <git repo> <s3 folder> <dev|staging|production|custom>"
	exit 1
fi

GIT_REPO=$1
S3_FOLDER_NAME=$2
QA_LEVEL=$3
BUILD_LEVEL=$3

# Switch to the git repo folder.
pushd $BASE/deployments/$GIT_REPO > /dev/null

# Make sure we're in the right branch and up-to-date.
echo "Updating the git branch."
GIT_BRANCH=master
BUILD_LEVEL=dev
if [[($QA_LEVEL != "dev")]]; then
	GIT_BRANCH=$QA_LEVEL
fi
if [[($QA_LEVEL = "staging") || ($QA_LEVEL = "production")]]; then
	BUILD_LEVEL=$QA_LEVEL
fi
git fetch -p
git checkout $GIT_BRANCH
git reset --hard origin/$GIT_BRANCH || git reset --hard $GIT_BRANCH

# Generate the version.
VERSION=$((node -p "require('./package.json').version" || true) 2> /dev/null)
if [[($VERSION = "")]]; then
	VERSION=$((cat version.txt || true) 2> /dev/null)
fi
if [[($VERSION = "")]]; then
	VERSION="1.0.0"
fi
echo "Using version $VERSION"

# Create the build folder and s3 folder if needed.
if [ ! -d $BASE/builds/$GIT_REPO-$BUILD_LEVEL/ ]; then
	echo "Creating build and S3 folders."
	mkdir -p $BASE/builds/$GIT_REPO-$BUILD_LEVEL/
	$BASE/pipelines/aws-s3-sync/sync.py update-manifest eyes-$BUILD_LEVEL/$S3_FOLDER_NAME
fi

# Build the app, which puts whatever it needs into the builds folder.
echo "Building the app."
./build.sh $BUILD_LEVEL $VERSION "$BASE/builds/$GIT_REPO-$BUILD_LEVEL"

# Generate the version file.
echo "$VERSION" > $BASE/builds/$GIT_REPO-$BUILD_LEVEL/version.txt

# AWS sync the files up to S3.
echo "Uploading the built app to the S3 folder."
$BASE/pipelines/aws-s3-sync/sync.py sync-s3-folder eyes-$BUILD_LEVEL/$S3_FOLDER_NAME $BASE/builds/$GIT_REPO-$BUILD_LEVEL

if [[($BUILD_LEVEL = "production")]]; then
	$BASE/pipelines/aws-s3-sync/invalidate.py E3JMG193HISS1S "/"$S3_FOLDER_NAME"/*"
fi

# Switch back to the called folder.
popd > /dev/null
