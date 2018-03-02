# Deploy App

This script goes through a bunch of steps to deploy an app into the AWS cloud. You can run it like this:

```
deploy_app.sh <git repo> <s3 folder> <qa level>
```

QA level can be either `dev`, `staging`, or `production`. It requires:

* A git repo in the `$HOME/deployments/` folder.
* A build.sh script within the git repo that does whatever is necessary to get files into the git repo's `dist` folder. The build.sh syntax must look like `build.sh <qa level> <version>`. Version is of the format `YYYY-MM-DD.\<qa level>.\<6 chars of last commit>`
* An existing AWS S3 folder in which the app will be deployed with an existing up-to-date manifest.txt file. It can be generated via `$HOME/pipelines/aws_s3_sync/sync.py update-manifest `eyes-\<QA level>/\<S3 folder name>`
