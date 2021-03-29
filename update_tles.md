There are multiple components to the TLE, spice, dynamo, and animdata pipeline: [tle_syncer](https://github.jpl.nasa.gov/VTAD/tle_syncer), [tle_to_spk](https://github.jpl.nasa.gov/VTAD/tle_to_spk), [dynamogen](https://github.jpl.nasa.gov/VTAD/dynamogen), [animdatagen](https://github.jpl.nasa.gov/VTAD/animdatagen), and [aws-s3-sync](https://github.jpl.nasa.gov/VTAD/aws-s3-sync). You can click the links to learn more about each in detail. In quick summary:

* tle_syncer - downloads TLEs from the CelesTrak database.
* tle_to_spk - uses the downloaded TLEs to create spice kernels.
* dynamogen - uses created spice to generate dynamo files.
* animdatagen - uses created spice to generate animdata files.
* aws-s3-sync - performs one-way sync in either direction of files to/from a local file system and an AWS S3 bucket and folders.

Note: All folders mentioned are within the pipeline home folder.

These have been placed in the pipelines folder. They are run by the script. In addition, it copies the output animdata files to /var/server/master/spice on blackhawk2 for use in dev environments.

The order of operations is this:

1. Backup the existing merged TLE file.
1. Run `pipelines/tle_syncer/sync.py` to download the latest TLEs from the CelesTrak database. It puts them all into a single merged TLE file.
1. Create a list of TLEs that have changed by comparing the old and new merged TLE files.
1. Run `pipelines/tle_to_spk/tle_to_spk.py` to update the spice in the `sources/spice` folder on each TLE that had changed.
1. Run `pipelines/animdatagen/animdatagen` to generate animdata into the `sources/animdata` folder.
1. Run `pipelines/dynamogen/dynamogen` to generate dynamo into the `sources/dynamo` folder.
1. For each animdata generated, copy that animdata folder to blackhawk2:/var/server/<qa level>/spice, for each level of qa: master (also called dev), staging, and production. Also run `pipelines/aws-s3-sync/sync.py` to upload that folder to the S3 buckets eyesstage and eyesstatic for staging and production, respectively.
1. For each dynamo generated, for each level of qa: master (also called dev), staging, and production, run `pipelines/aws-s3-sync/sync.py` to upload that folder to the S3 buckets eyes-dev, eyes-staging, eyes-production, respectively.
1. Upload the TLE files, including the merged one, to CloudFront using `pipelines/aws-s3-sync/sync.py`.
