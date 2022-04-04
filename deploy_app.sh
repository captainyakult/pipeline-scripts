#!/bin/bash

# Fail on any error.
set -eo pipefail

# Get the base folder of the system.
BASE=$(cd "$(dirname "$0")/../.."; pwd)

if [[ ($# -lt 5) ]]; then
	echo "usage: deploy_app.sh <git repo> <git branch> <build level=dev|production> <deployment folder> <deployment level=local|dev|staging|production> [addversion]"
	exit 1
fi

GIT_REPO=$1
GIT_BRANCH=$2
BUILD_LEVEL=$3
DEPLOYMENT_FOLDER_NAME=$4
DEPLOYMENT_LEVEL=$5
ADD_VERSION=$6

# Make sure the deployment level is valid.
if ! [[ $DEPLOYMENT_LEVEL =~ ^(local|dev|staging|production)$ ]]; then
	echo "The deployment level may either be local, dev, staging, or production."
	exit 1
fi

# Make sure the deployment folder name is valid.
if ! [[ $DEPLOYMENT_FOLDER_NAME =~ ^(apps|libs|(assets/static)).* ]]; then
	echo "If installing locally, you must choose a deployment folder that starts with 'apps', 'libs', or 'assets/static'."
	exit 1
fi

# Switch to the git repo folder.
pushd $BASE/data/deployments/$GIT_REPO > /dev/null

# Make sure we're in the right branch and up-to-date.
echo "Updating the git branch."
git fetch -p
git checkout $GIT_BRANCH
git reset --hard origin/$GIT_BRANCH || git reset --hard $GIT_BRANCH

# Generate the version.
VERSION=$((grep "\"version\"\w*:" package.json | awk -F'"' '{print $4}' || true) 2> /dev/null)
if [[($VERSION = "")]]; then
	VERSION=$((cat version.txt || true) 2> /dev/null)
fi
if [[($VERSION = "")]]; then
	VERSION="1.0.0"
fi
echo "Using version $VERSION"

# Create the build folder and s3 folder if needed.
if [ ! -d $BASE/temp/build-$GIT_REPO-$DEPLOYMENT_LEVEL/ ]; then
	echo "Creating build folder."
	mkdir -p $BASE/temp/build-$GIT_REPO-$DEPLOYMENT_LEVEL/
fi

# Build docker image.
echo "Building the docker image."
docker build -t $GIT_REPO . > /dev/null

# Run the docker image as a container.
echo "Building the app within the docker container."
docker run --rm -v $BASE:$BASE -v $BASE/.ssh:/root/.ssh $GIT_REPO \
	/bin/bash -c " \
	adduser -h $BASE -D -u $(id -u $USER) -s /bin/bash $USER && \
	su - $USER -c \"cd $BASE/data/deployments/$GIT_REPO; ./build.sh $BUILD_LEVEL $VERSION $BASE/temp/build-$GIT_REPO-$DEPLOYMENT_LEVEL\""

# Generate the version file.
echo "$VERSION" > $BASE/temp/build-$GIT_REPO-$DEPLOYMENT_LEVEL/version.txt

if [[($DEPLOYMENT_LEVEL != "local")]]; then
	# AWS sync the files up to S3.
	echo "Uploading the built app to the S3 eyes-$DEPLOYMENT_LEVEL/$DEPLOYMENT_FOLDER_NAME folder."
	$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-$DEPLOYMENT_LEVEL/$DEPLOYMENT_FOLDER_NAME $BASE/temp/build-$GIT_REPO-$DEPLOYMENT_LEVEL
	if [[($ADD_VERSION == "addversion")]]; then
		echo "Uploading the built app to the S3 eyes-$DEPLOYMENT_LEVEL/$DEPLOYMENT_FOLDER_NAME-$VERSION folder."
		$BASE/code/aws-s3-sync/sync.sh sync-s3-folder eyes-$DEPLOYMENT_LEVEL/$DEPLOYMENT_FOLDER_NAME-$VERSION $BASE/temp/build-$GIT_REPO-$DEPLOYMENT_LEVEL
	fi

	if [[($DEPLOYMENT_LEVEL = "production")]]; then
		$BASE/code/aws-s3-sync/invalidate.sh E3JMG193HISS1S "/"$DEPLOYMENT_FOLDER_NAME"/*"
		$BASE/code/aws-s3-sync/invalidate.sh E3JMG193HISS1S "/"$DEPLOYMENT_FOLDER_NAME-$VERSION"/*"
	fi
else
	echo "Syncing the built app to the local $BASE/data/www/$DEPLOYMENT_FOLDER_NAME folder."
	mkdir -p $BASE/data/www/$DEPLOYMENT_FOLDER_NAME/
	rsync -rtv --delete $BASE/temp/build-$GIT_REPO-$DEPLOYMENT_LEVEL/ $BASE/data/www/$DEPLOYMENT_FOLDER_NAME/
	if [[($ADD_VERSION == "addversion")]]; then
		echo "Syncing the built app to the local $BASE/data/www/$DEPLOYMENT_FOLDER_NAME-$VERSION folder."
		mkdir -p $BASE/data/www/$DEPLOYMENT_FOLDER_NAME-$VERSION/
		rsync -rtv --delete $BASE/temp/build-$GIT_REPO-$DEPLOYMENT_LEVEL/ $BASE/data/www/$DEPLOYMENT_FOLDER_NAME-$VERSION/
	fi
fi

# Switch back to the called folder.
popd > /dev/null
