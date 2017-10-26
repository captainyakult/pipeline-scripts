There are three components to the spice & animdata pipeline: spice_syncer, animdatagen, and aws_s3_sync. You can click the links to learn more about each in detail. In quick summary:

* spice_syncer - downloads spice from the NAIF and SPS file servers. It performs a one-way sync from the file servers to a specified folder.
* animdatagen - uses downloaded spice to generate animdata files.
* aws_s3_sync - performs one-way sync in either direction of files to/from a local file system and an AWS S3 bucket and folders.

Note: All folder mentions are within the pipeline home folder on blackhawk-blade.

These have been placed in the pipelines folder. They are run by a "update_animdata.sh" script in the pipelines/scripts folder. In addition, it copies the output animdata files to /var/server/master/spice on blackhawk2 for use in dev environments.

