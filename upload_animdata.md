Uploads a single body to either dev, staging, or production. You can run it like this:

`./upload_animdata.sh sc_maven/earth dev`

This will upload the animdata in $HOME/sources/animdata/sc_maven/earth to blackhawk2/var/repository/master/spice/sc_maven/earth. If you choose staging or production, it will also use aws-s3-sync to upload (no manifest) the files to the eyesstage and eyesstatic buckets respectively.
