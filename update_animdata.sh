#! /bin/bash

# fail on any error
set -e

# make sure the library path is set correctly
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/gcc-4.9.0/lib64

# spice_syncer
$HOME/pipelines/spice_syncer/sync.py -d $HOME/sources/spice -u $HOME/logs/spice_syncer_updated_spice.log >> $HOME/logs/spice_syncer.log 2>&1

# animdatagen
pushd $HOME/pipelines/animdatagen > /dev/null
./animdatagen --update --spice $HOME/sources/spice --output $HOME/sources/animdata --list $HOME/logs/spice_syncer_updated_spice.log --updatedAnimdataFile $HOME/logs/animdatagen_updated_animdata.log >> $HOME/logs/animdatagen.log 2>&1
popd > /dev/null
rm $HOME/logs/spice_syncer_updated_spice.log

# copy to blackhawk and aws s3
while read folder
do
	scp -r -p -q $HOME/sources/animdata/$folder/* pipeline@blackhawk2:/var/server/master/spice/$folder/
	scp -r -p -q $HOME/sources/animdata/$folder/* pipeline@blackhawk2:/var/server/staging/spice/$folder/
	$HOME/pipelines/aws_s3_sync/sync.py upload-folder eyesstage/server/spice/$folder $HOME/sources/animdata/$folder >> $HOME/logs/aws_s3_sync.log 2>&1
	scp -r -p -q $HOME/sources/animdata/$folder/* pipeline@blackhawk2:/var/server/production/spice/$folder/
	$HOME/pipelines/aws_s3_sync/sync.py upload-folder eyesstatic/server/spice/$folder $HOME/sources/animdata/$folder >> $HOME/logs/aws_s3_sync.log 2>&1
done < $HOME/logs/animdatagen_updated_animdata.log
rm $HOME/logs/animdatagen_updated_animdata.log
