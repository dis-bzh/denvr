# Denv-r template project

This project is a template to :

- test, build and push a contenerized node app in Github registry
- managed VMs in Denv-r cloud environment and deploy the previous contenerized app on it/them.

## Github workflow

Template for testing node app then build it using Docker and push it in Github registry.

## Ansible

Template to manage VMs configuration. It uses the inventory created by Terraform.

### Content organisation

https://docs.ansible.com/ansible/2.9/user_guide/playbooks_best_practices.html#content-organization

production                # inventory file for production servers
staging                   # inventory file for staging environment

group_vars/
   group1.yml             # here we assign variables to particular groups
   group2.yml
host_vars/
   hostname1.yml          # here we assign variables to particular systems
   hostname2.yml

library/                  # if any custom modules, put them here (optional)
module_utils/             # if any custom module_utils to support modules, put them here (optional)
filter_plugins/           # if any custom filter plugins, put them here (optional)

site.yml                  # master playbook
webservers.yml            # playbook for webserver tier
dbservers.yml             # playbook for dbserver tier

roles/
    common/               # this hierarchy represents a "role"
        tasks/            #
            main.yml      #  <-- tasks file can include smaller files if warranted
        handlers/         #
            main.yml      #  <-- handlers file
        templates/        #  <-- files for use with the template resource
            ntp.conf.j2   #  <------- templates end in .j2
        files/            #
            bar.txt       #  <-- files for use with the copy resource
            foo.sh        #  <-- script files for use with the script resource
        vars/             #
            main.yml      #  <-- variables associated with this role
        defaults/         #
            main.yml      #  <-- default lower priority variables for this role
        meta/             #
            main.yml      #  <-- role dependencies
        library/          # roles can also include custom modules
        module_utils/     # roles can also include custom module_utils
        lookup_plugins/   # or other types of plugins, like lookup in this case

    webtier/              # same kind of structure as "common" was above, done for the webtier role
    monitoring/           # ""
    fooapp/               # ""

### Project configuration file

Copy and edit the ansible configuration file example with the inventory path, your SSH private key file path corresponding to the public part used in Terraform and the user on deployed VMs.

```bash
cp ansible.cfg.example ansible.cfg
```

## Terraform

### variables

```bash
cp terraform.tfvars.example teraform.tfars
```
and edit it

