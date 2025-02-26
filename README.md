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
--extra-vars host_port=80
--extra-vars container_port=80
```

## Terraform

Terraform is not integrated in the CI for now.
To create and manage compute and storage resources like Virtual Machines using Terraform you must register a new API token at your [user interface](https://app.denv-r.com/)

### S3 backend

The Terraform State (tfstate) should be considered as a secret and its very important to keep it safe.
Using an S3 backend is one of the best practice option (avoid using static file in production).

You can create an S3 bucket from the UI or calling the API according to [the Denv-r API documentation](https://api.denv-r.com/#create-bucket).

```bash
curl --location --request PUT "https://api.denv-r.com/v1/storage/bucket" \
    -H "apikey: meowmeowmeow" \
    -d "name=pang1" \
    -d "billing_account_id=12345"
```

Then retrieve (or generate) `accessKey` and `secretKey`

```bash
curl "https://api.denv-r.com/v1/storage/user/keys" \
    -H "apikey: meowmeowmeow" \
    -X GET
```

### variables

backend.tfvars file contains S3 backend configuration, as backend is loading first.
terraform.tfvars file contains the details of your infrastructure like the networks, the number of Vms, the resources you will allocate to them, ...

```bash
cp backend.tfvars.example backend.tfars
cp terraform.tfvars.example terraform.tfars
```

To create and manage your infrastructure, just provide the Denv-r API Token, S3 access key and S3 secret key then execute the commands below.

```bash
export TF_VAR_api_token="xxx"
# $env:TF_VAR_api_token="xxx" in Powershell

terraform init -backend-config=backend.tfvars
terraform plan -out tf.plan
terraform apply "tf.plan"
```
