# pozoledf-sample-app-deployment

[PozoleDF](https://github.com/kuritsu/pozoledf) Sample NodeJS Application Kubernetes deployment configuration.

## Repository structure

This repository has 3 types of deployment configuration:

- [Chef cookbook](https://docs.chef.io/cookbooks/), in the base directory. Contains the Chef recipes
  to deploy the manifests of the [Sample App](https://github.com/kuritsu/pozoledf-sample-app) in the Kubernetes controller node.
- [Kubernetes manifests](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/),
  under the `files/manifests` directory. Contains all the Kubernetes resources declared in YAML files
  to be deployed (created/modified) on the Kubernetes cluster. They reference the Docker image of
  the Sample App application.
- [Chef environment](https://docs.chef.io/environments/) configuration, under the `environments` directory.
  Contains subdirectories named after all the environments -staging, production1, production2, etc-
  in which the app will be deployed. The `environment.json` files specify which cookbook version
  containing the app manifests will be applied to that environment.
  **Note that this directory will be the primary source of truth regarding the configuration of
  the existing environments, thus following the
  [GitOps](https://www.cloudbees.com/gitops/what-is-gitops) paradigm.**

## Versioning strategy explained

The main branch of this repo contains the **truth, applied** basic configuration.

Note that [pozoledf-sample-app](https://github.com/kuritsu/pozoledf-sample-app)'s Jenkins pipeline
will check out the main branch of this repo, create a new branch called
v`majorVersion.minorVersion.patch` after a successful build and push it to GitHub.

Once the new branch has been pushed, the Jenkins pipeline of this project triggers and performs
the following actions:
- Update the `files/manifests/kustomization.yml` with the full Docker image name and new tag version,
  named after the branch.
- Change the `metadata.rb` file, to reflect the new version.
- Deploy the versioned cookbook to the Chef Infra Server.

The branch will remain open, as it can be seen as a release branch. You can perform some of these
actions to modify the release:
- Update the YAML files in the `files/manifests` directory to change the K8S resources.
- Change the recipes of the cookbook, in case a new set of actions is needed for the deployment.
- Modify the environment configuration under `environments`, so when the branch gets merged in
  the main branch the environments are updated accordingly.

When you commit your changes to the release branch, the cookbook will be updated as well in the
Chef Infra server. You can then open a Pull Request to be approved by your team in order to apply the
updated environment configuration.

When the main branch of this repo triggers, the Jenkins pipeline will perform the following steps:
- Update the Chef Infra Server with all the environment configuration contained in the
  `environments` directory.

Every 10-30 minutes, all Chef Infra clients will request its configuration data from the Infra Server,
and thus the new configuration will be applied. *We recommend that this cookbook should contain a notification
step after the `default` recipe is applied. You can use a Slack message, for example, to indicate that
the deployment/update has been performed successfully in the environment.*

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
