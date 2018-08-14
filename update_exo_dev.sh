#!/bin/bash

$HOME/pipelines/exo-pipeline-scripts/generateEoX_Ranger.sh $HOME/generated-data/exo-pipeline-scripts-data/ http://blackhawk-blade.jpl.nasa.gov:7000/ >> $HOME/logs/exo-pipeline-scripts.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py upload-folder eyes-dev/assets/dynamic/exo/db $HOME/generated-data/exo-pipeline-scripts-data >> $HOME/logs/aws_s3_sync.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py update-manifest eyes-dev/assets/dynamic/exo/db >> $HOME/logs/aws_s3_sync.log 2>&1