pushd $HOME/pipelines/animdatagen > /dev/null
./animdatagen --verbose --spice $HOME/sources/spice --output $HOME/sources/animdata --config json/$1.json
popd > /dev/null
