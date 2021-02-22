# pozoledf-sample-app-deployment

[PozoleDF](https://github.com/kuritsu/pozoledf) Sample NodeJS Application Kubernetes deployment manifests.

## Deployment versioning strategy explained

The main branch of this repo will contain the basic configuration.

Note that [pozoledf-sample-app](https://github.com/kuritsu/pozoledf-sample-app)'s Jenkins pipeline
will check out the main branch of this repo, create a new branch called
v`majorVersion.minorVersion.patch` after a successful build, and change the `kustomization.yml` file
with the full Docker image name and versioned tag.

Once the new branch has been pushed, the Jenkins pipeline of this project triggers,
the main branch of the [pozoledf-sample-app-chef](https://github.com/kuritsu/pozoledf-sample-app-chef)
is checked out, and a new branch named after the same artifact version is created.
This branch will include:

- The new version in its `metadata.rb` file (cookbook version).
- This repository's source code compressed (from the versioned branch).

Once commited, the branch will be pushed to GitHub.

By default, it will also be merged automatically in the main branch with `--force`. **This behavior can be changed.**

The [pozoledf-sample-app-chef](https://github.com/kuritsu/pozoledf-sample-app-chef) project has a
Jenkins pipeline that when the main branch changes, the Infra Chef Server will be automatically
updated with the new cookbook, thus making it available for installation.

## Specific environment configuration

Sensitive information such as connection strings and passwords must be stored as Kubernetes secrets.
For such purpose, you can use the [kustomize syntax](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/secretGeneratorPlugin.md) to get the secrets from the local filesystem.
See the example below:

```yaml
# kustomization.yaml
...

secretGenerator:
- name: mysecrets
  env:
  - /var/lib/myapp/env
  files:
  - /var/lib/myapp/secret.txt

...
```
You will need to create the files locally in the Kubernetes controller, but you will be able to
reference them from your manifests.
