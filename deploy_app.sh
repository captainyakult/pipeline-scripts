#!/bin/bash

# This script deploys an app to the cloud.

set -e

if [[ ($# -ne 3) || (($3 != "dev") && ($3 != "staging") && ($3 != "production")) ]] ; then
	echo "usage: deploy_app.sh <git repo> <s3 folder> <dev|staging|production>"
	exit 1
fi

GIT_REPO=$1
S3_FOLDER_NAME=$2
QA_LEVEL=$3

# Switch to the git repo folder.
pushd $HOME/deployments/$GIT_REPO > /dev/null

# Make sure we're in the right branch and up-to-date.
GIT_BRANCH=master
if [[($QA_LEVEL = "staging") || ($QA_LEVEL = "production")]]; then
	GIT_BRANCH=$QA_LEVEL
fi
git fetch -p
git reset --hard origin/$GIT_BRANCH

# Build the app, which puts whatever it needs into the dist folder.
./build.sh $QA_LEVEL

# Generate the version file.
VERSION=$(date -u +"%Y-%m-%d").$QA_LEVEL.$(git log --format="%h" -n 1)
echo "$VERSION" > dist/version.txt

# Rsync the files into the build folder.
mkdir -p $HOME/builds/$GIT_REPO-$QA_LEVEL/
rsync -arvz --exclude=".[!.]*" --exclude 'deploy*' --delete --delete-excluded dist/ $HOME/builds/$GIT_REPO-$QA_LEVEL/

# AWS sync the files up to S3.
$HOME/pipelines/aws_s3_sync/sync.py sync-s3-folder eyes-$QA_LEVEL/$S3_FOLDER_NAME $HOME/builds/$GIT_REPO-$QA_LEVEL

# Switch back to the called folder.
popd > /dev/null
