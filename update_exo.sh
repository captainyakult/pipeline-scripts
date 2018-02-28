$HOME/pipelines/exo-pipeline-scripts/generateEoX_Ranger.sh $HOME/generated-data/exo-pipeline-scripts-data/ http://magic.jpl.nasa.gov:7000/ >> $HOME/logs/exo-pipeline-scripts.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py upload-folder eyes-dev/ranger/exo-kiosk/static/exo/db $HOME/generated-data/exo-pipeline-scripts-data >> $HOME/logs/aws_s3_sync.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py update-manifest eyes-dev/ranger/exo-kiosk >> $HOME/logs/aws_s3_sync.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py upload-folder eyes-staging/ranger/exo-kiosk/static/exo/db $HOME/generated-data/exo-pipeline-scripts-data >> $HOME/logs/aws_s3_sync.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py update-manifest eyes-staging/ranger/exo-kiosk >> $HOME/logs/aws_s3_sync.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py upload-folder eyes-production/ranger/exo-kiosk/static/exo/db $HOME/generated-data/exo-pipeline-scripts-data >> $HOME/logs/aws_s3_sync.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py update-manifest eyes-production/ranger/exo-kiosk >> $HOME/logs/aws_s3_sync.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py upload-folder eyes-dev/ranger/exo/static/exo/db $HOME/generated-data/exo-pipeline-scripts-data >> $HOME/logs/aws_s3_sync.log 2>&1

$HOME/pipelines/aws_s3_sync/sync.py update-manifest eyes-dev/ranger/exo >> $HOME/logs/aws_s3_sync.log 2>&1
