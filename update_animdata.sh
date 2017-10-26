$HOME/pipelines/spice_syncer/sync.py -d $HOME/sources/spice -u $HOME/logs/spice_syncer_updated_spice.log >> $HOME/logs/spice_syncer.log
pushd $HOME/pipelines/animdatagen > /dev/null
./animdatagen --update --spice $HOME/sources/spice --output $HOME/sources/animdata --list $HOME/logs/spice_syncer_updated_spice.log --updatedAnimdataFile $HOME/logs/animdatagen_updated_animdata.log >> $HOME/logs/animdatagen.log
popd > /dev/null
rm $HOME/logs/spice_syncer_updated_spice.log
while read folder
do
	scp -r -p -q $HOME/sources/animdata/$folder/* pipeline@blackhawk2:/var/server/master/spice/$folder/
	#$HOME/pipelines/aws_s3_sync/sync.py upload-folder eyestest/$folder $HOME/sources/animdata/$folder >> $HOME/logs/aws_s3_sync.log
done < $HOME/logs/animdatagen_updated_animdata.log
rm $HOME/logs/animdatagen_updated_animdata.log
