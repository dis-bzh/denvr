# WIP Denv-r template project

> [!WARNING]
> Work In Progress
> All best pratices aren't applied for now :
> - environments
> - tests
> - ...

This project is a template to :

- build and push a contenerized NextJS app in Github registry
- managed VMs in Denv-r cloud environment using Terraform*
- deploy the previous contenerized app on it/them using Ansible

> [!NOTE]
> This Terraform project is just for Denv-r cloud env using the Warren provider
> But, you still can use the CI and Ansible to build, publish and deploy your NextJS app in your VMs. You just need to create an inventory with their IP address (The VMs must be available through SSH)

## Prerequisites

Using the CI/CD only, to build, push and deploy, you just need to install :
- Terraform

If you want to run all this actions locally first then you need :
- npm : build and run locally the NextJS application following the README.md file on "my-app" sub-directory
- Docker with docker compose : build and run contenerized version of the app
- Terraform : deploy VMs in your Denv-r cloud environment
- Ansible : deploy the contenerized app on your VMs

## Github workflow

- snyk.yml : Security scan
- build.yml : Build container image and push it in Github registry => triggered when pushing a tag
- deploy.yml : Deploy the container using ansible playbook => triggered when "build and push" workflow is completed

### Github variables
Secrets :
- ANSIBLE_USER : User used by ansible to connect and execute command on VMs
- SSH_PRIVATE_KEY : SSH key corresponding to the ansible user
- SNYK_TOKEN : Snyk API Token for security scan

## Ansible

Template to manage VMs configuration. It uses the inventory created by Terraform.
It can be run locally, automatically triggered in the CI when "Build and Push" workflow is "completed", manually in the CI.

To run it locally, use the following command :
```bash
ansible-playbook -i path/to/inventory path/to/playbook.yml \
--private-key path/to/sshPrivateKey \
-u username \
--ssh-common-args='-o StrictHostKeyChecking=no' \
--extra-vars ansible_user=username \
--extra-vars registry_username=github_username \
--extra-vars registry_token=github_access_token \
--extra-vars image_name=containerImage:tag
```

## Terraform

Terraform is not integrated in the CI for now
The Terraform S3 backend seems to not be compatible with warren/Denv-r cloud

### variables

```bash
cp terraform.tfvars.example teraform.tfars
```

edit it then retrieve your Denv-r API Token and execute :

```bash
export TF_VAR_api_token = xxx

terraform init
terraform plan -out tf.plan
terraform apply "tf.plan"
```
