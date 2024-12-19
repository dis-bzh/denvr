# WIP Denv-r template project

> [!WARNING]
> Work In Progress
> All best pratices aren't applied for now :
> - environments
> - tests
> - ...

This project is a template to :

- test, build and push a contenerized node app in Github registry
- managed VMs in Denv-r cloud environment and deploy the previous contenerized app on it/them.

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

The playbook runs from Github actions but you can execute it using :
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
