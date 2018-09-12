There are three components to the spice, dynamo, and animdata pipeline: [spice_syncer](https://github.jpl.nasa.gov/VTAD/spice_syncer), [dynamogen](https://github.jpl.nasa.gov/VTAD/dynamogen), [animdatagen](https://github.jpl.nasa.gov/VTAD/animdatagen), and [aws_s3_sync](https://github.jpl.nasa.gov/VTAD/aws_s3_sync). You can click the links to learn more about each in detail. In quick summary:

* spice_syncer - downloads spice from the NAIF and SPS file servers. It performs a one-way sync from the file servers to a specified folder.
* dynamogen - uses downloaded spice to generate dynamo files.
* animdatagen - uses downloaded spice to generate animdata files.
* aws_s3_sync - performs one-way sync in either direction of files to/from a local file system and an AWS S3 bucket and folders.

Note: All folder mentions are within the pipeline home folder.

These have been placed in the pipelines folder. They are run by the script. In addition, it copies the output animdata files to /var/server/master/spice on blackhawk2 for use in dev environments.

The order of operations is this:

1. Run `pipelines/spice_syncer/sync.py` to update the spice in the `sources/spice` folder. It outputs which subfolders of the `sources/spice` folder were updated in the `logs/spice_syncer_updated_spice.log` file.
1. Run `pipelines/animdatagen/animdatagen` to generate animdata using the generated `logs/spice_syncer_updated_spice.log` as a list into the `sources/animdata` folder. It will only generate from config files that use the spice folders in the list and only if the config has `excludeFromListProcessing` omitted or set to false. It outputs which animdatagen folders were generated to `logs/animdatagen_updated_animdata.log`.
1. Run `pipelines/animdatagen/dynamogen` to generate dynamo using the generated `logs/spice_syncer_updated_spice.log` as a list into the `sources/dynamo` folder. It will only generate from config files that use the spice folders in the list and only if the config has `excludeFromListProcessing` omitted or set to false. It outputs which dynamogen folders were generated to `logs/dynamogen_updated_dynamo.log`.
1. For each line in `logs/animdatagen_updated_animdata.log`, copy that animdata folder to blackhawk2:/var/server/<qa level>/spice, for each level of qa: master (also called dev), staging, and production. Also run `pipelines/aws_s3_sync/sync.py` to upload that folder to the S3 buckets eyesstage and eyesstatic for staging and production, respectively.
1. For each line in `logs/dynamogen_updated_dynamo.log`, for each level of qa: master (also called dev), staging, and production, run `pipelines/aws_s3_sync/sync.py` to upload that folder to the S3 buckets eyes-dev, eyes-staging, eyes-production, respectively.
