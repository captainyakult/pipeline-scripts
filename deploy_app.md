# Deploy App

This script goes through a bunch of steps to deploy an app into the AWS cloud. You can run it like this:

```
deploy_app.sh <git repo> <s3 folder> <dev|staging|production>
```

It requires:

* A git repo in the `$HOME/deployments/` folder.
* A build.sh script within the git repo that does whatever is necessary to get files into the git repo's `dist` folder.
* An existing AWS S3 folder in which the app will be deployed with an existing up-to-date manifest.txt file. It can be generated via `$HOME/pipelines/aws_s3_sync/sync.py update-manifest `eyes-\<QA level>/\<S3 folder name>`
