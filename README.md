# pozoledf-sample-app-deployment

[PozoleDF](https://github.com/kuritsu/pozoledf) [Sample App](https://github.com/kuritsu/pozoledf-sample-app) deployment configuration.

## Repository structure

This repository has 3 types of deployment configuration:

- [Chef Habitat Package](https://docs.chef.io/habitat/pkg_build), in the habitat directory. It contains the package configuration and scripts to deploy and monitor the app in Kubernetes (`habitat/hooks` dir). As you may notice, it will use the `kubectl apply -k` command to parse the [kustomize] config and apply the generated k8s resources in the `pozoledf` namespace.
- [Kubernetes manifests](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/), under the `habitat/config_install` directory. Contains all the Kubernetes resources declared in YAML files to be deployed (created/modified) on the Kubernetes cluster. They reference the Docker image of the Sample App application.
- Environment release configuration, in the `release.json` file. This indicates which version of the app (and corresponding Habitat package) will be deployed per environment.
Notice that this file will be used by the Jenkins pipeline to perform the corresponding [package promotions](https://docs.chef.io/habitat/pkg_promote/) to the indicated Habitat channels -each environment corresponds to a channel.

## Building

The Jenkinsfile in this repo requires the following secrets to be created in Jenkins:

- `docker-registry-fqdn` (text): Host name of the Docker Registry you'll be using for storing your Docker images. Ex: `myregistry.mycompany.com`.
- `hab-origin` (text): Name of the company you used when installing the Chef Infra Server/Automate node. Ex: `myorg`.
- `hab-token` (text): Prerequisite for getting it is to follow the steps indicated [here](https://github.com/kuritsu/pozoledf-chef-repo/tree/main/roles#habitat-channels). Once you generate the `/var/chef/builder-token`, you will use it as this secret.
- `hab-builder-url` (text): Use `https://chef-automate.private.com/bldr/v1`, replace with your actual Chef Automate host name and keep the path part.
- `hab-builder-certificate` (file): This is a certificate file, which you can find at `/opt/chef-server-install/ssl-certificate.crt` on the Chef Automate host.

**Note:** The PozoleDF install script for the Jenkins node should create most of these secrets.

## Versioning strategy explained

The main branch of this repo contains the **truth, applied** basic configuration.

Note that [pozoledf-sample-app](https://github.com/kuritsu/pozoledf-sample-app)'s Jenkins pipeline will check out the main branch of this repo, create a new branch called v`majorVersion.minorVersion.patch` after a successful build, will update `habitat/config_install/kustomization.yml` with the full Docker image name and new tag version, and the `dev` environment in the `release.json` file. It will then commit and push it to GitHub.

Once the new branch has been pushed, the Jenkins pipeline of this project triggers and performs the following actions:
- Updates the `plan.sh` file, to reflect the new version.
- Deploys the versioned Habitat package to the on-prem [Habitat Builder](https://github.com/habitat-sh/on-prem-builder) service.

The branch will remain open, as it can be seen as a release branch. You can perform some of these actions to modify the release:
- Update the YAML files in the `habitat/config_install` directory to change the K8S resources.
- Change the Habitat package config, in case a new set of actions is needed for the deployment.
- Modify the `release.json` file, so when the branch gets merged in main the environments are updated accordingly (when the Habitat package gets promoted).

When you commit your changes to the release branch, the Habitat package config will be updated and the latest package will be promoted to the `dev` environment/channel. You can then open a Pull Request to be approved by your team in order to apply the updated environment configuration.

When the main branch of this repo changes, the Jenkins pipeline will perform the following steps:
- Detect what was the latest releases of the app/package versions mentioned in `release.json`.
- Promote the latest release of the version indicated per environment to the corresponding Chef Habitat channel.

After promotion, the [Habitat Supervisor](https://docs.chef.io/habitat/sup/) service running in a Kubernetes control plane (you need 1 per environment) will detect the package update, and will perform the steps to deploy the updated k8s manifests in the node.

You can track which app version is deployed in which environment from the [Applications dashboard](https://docs.chef.io/automate/applications_dashboard/) of Chef Automate.

## Specific environment configuration

Sensitive information such as connection strings and passwords must be stored as Kubernetes secrets. For such purpose, you can use the [kustomize syntax](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/secretGeneratorPlugin.md) to get the secrets from the local filesystem. See the example below:

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
You will need to create the files locally in the Kubernetes controller, but you will be able to reference them from your manifests.
