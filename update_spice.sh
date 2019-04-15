#! /bin/bash

# fail on any error
set -e

LOGS=$HOME/logs
SPICE_SYNCER=$HOME/pipelines/spice_syncer
ANIMDATAGEN=$HOME/pipelines/animdatagen
DYNAMOGEN=$HOME/pipelines/dynamogen
AWS_S3_SYNC=$HOME/pipelines/aws_s3_sync
SPICE=$HOME/sources/spice
ANIMDATA=$HOME/sources/animdata
DYNAMO=$HOME/sources/dynamo

# make sure the library path is set correctly
# make sure the path and library path is set correctly
export PATH=/usr/local/gcc-4.9.0/bin:$HOME/pipelines/animdatagen/cspice/exe:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/gcc-4.9.0/lib64

# spice_syncer
$SPICE_SYNCER/sync.py -d $SPICE -u $LOGS/spice_syncer_updated_spice.log >> $LOGS/spice_syncer.log 2>&1

# animdatagen
pushd $ANIMDATAGEN > /dev/null
./animdatagen --update --spice $SPICE --output $ANIMDATA --list $LOGS/spice_syncer_updated_spice.log --updatedAnimdataFile $LOGS/animdatagen_updated_animdata.log >> $LOGS/animdatagen.log 2>&1
popd > /dev/null

# dynamogen
pushd $DYNAMOGEN > /dev/null
./dynamogen --update --spice $SPICE --output $DYNAMO --list $LOGS/spice_syncer_updated_spice.log --updatedFile $LOGS/dynamogen_updated_dynamo.log >> $LOGS/dynamogen.log 2>&1
popd > /dev/null
rm -f $LOGS/spice_syncer_updated_spice.log

# copy animdata to blackhawk and sync to aws s3
while read folder
do
	ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/master/spice/$folder/"
	scp -r -p -q $ANIMDATA/$folder/* pipeline@blackhawk2:/var/server/master/spice/$folder/
	ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/staging/spice/$folder/"
	scp -r -p -q $ANIMDATA/$folder/* pipeline@blackhawk2:/var/server/staging/spice/$folder/
	$AWS_S3_SYNC/sync.py upload-folder eyesstage/server/spice/$folder $ANIMDATA/$folder >> $LOGS/aws_s3_sync.log 2>&1
	ssh -n -q pipeline@blackhawk2 "mkdir -p /var/server/production/spice/$folder/"
	scp -r -p -q $ANIMDATA/$folder/* pipeline@blackhawk2:/var/server/production/spice/$folder/
	$AWS_S3_SYNC/sync.py upload-folder eyesstatic/server/spice/$folder $ANIMDATA/$folder >> $LOGS/aws_s3_sync.log 2>&1
done < $LOGS/animdatagen_updated_animdata.log
rm -f $LOGS/animdatagen_updated_animdata.log

# sync dynamo to aws s3
while read folder
do
	folder=`echo $folder | cut -d/ -f1`
        $AWS_S3_SYNC/sync.py sync-s3-folder eyes-dev/assets/dynamic/dynamo/$folder $DYNAMO/$folder >> $LOGS/aws_s3_sync.log 2>&1
        $AWS_S3_SYNC/sync.py sync-s3-folder eyes-staging/assets/dynamic/dynamo/$folder $DYNAMO/$folder >> $LOGS/aws_s3_sync.log 2>&1
        $AWS_S3_SYNC/sync.py sync-s3-folder eyes-production/assets/dynamic/dynamo/$folder $DYNAMO/$folder >> $LOGS/aws_s3_sync.log 2>&1
done < $LOGS/dynamogen_updated_dynamo.log
rm -f $LOGS/dynamogen_updated_dynamo.log

