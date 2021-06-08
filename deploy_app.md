# Deploy App

This script goes through a bunch of steps to deploy an app into the AWS cloud. You can run it like this:

```
deploy_app.sh <git repo> <git branch> <build level=dev|production> <deployment folder> <deployment level=dev|staging|production>
```

Git repo is the git repo within the ~/deployments folder to use.
Git branch is the branch of the repo that will be used.
Build level is either dev or production. It usually is used for choosing a debug or production/minified version of your application.
Deployment folder is where in the S3 bucket the app will go. It is usually 'apps/<your app name>'.
Deployment level is either dev, staging, or production. It tells the script which S3 bucket to place the app in.

Before running this script, the app requires:

* A git repo in the `$HOME/deployments/` folder.
* A build.sh script within the git repo that does whatever is necessary to get files into the `build` folder. The build.sh syntax must look like `build.sh <qa level> <version> <build folder>`.
* An existing AWS S3 folder in which the app will be deployed with an existing up-to-date manifest.txt file. It can be generated via `$HOME/pipelines/aws-s3-sync/sync.py update-manifest `eyes-\<QA level>/\<S3 folder name>`
