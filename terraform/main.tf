
# Resources managed by Terraform

# Networks
resource "warren_network" "networks" {
  for_each = toset(var.networks_names)
  name = "net-${var.prefix}-${each.key}"
}

# VMs
resource "warren_virtual_machine" "denvr_vms" {
    for_each   = {
      for index, vm in var.vms:
      vm.name => vm
    }
    disk_size_in_gb = each.value.disk_size
    memory          = each.value.ram_number
    name            = "vm-${var.prefix}-${each.value.name}"
    username        = "${var.username}"
    os_name         = "${var.os_name}"
    os_version      = "${var.os_version}"
    vcpu            = each.value.cpu_number
    network_uuid    = resource.warren_network.networks[each.value.network].id
    reserve_public_ip = false
    public_key      = "${var.ssh_public_key}"
}

# IPs associated to VMs (Only if public_ip is true)
resource "warren_floating_ip" "denvr_ip" {
  for_each = {
    for vm in var.vms : vm.name => vm
    if vm.public_ip
  }
  name        = "ip-${var.prefix}-${each.value.name}"
  assigned_to = resource.warren_virtual_machine.denvr_vms[each.key].id
}

# Génération de l'inventaire Ansible à partir des outputs Terraform
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    vms        = resource.warren_virtual_machine.denvr_vms
    public_ips = resource.warren_floating_ip.denvr_ip
  })
  filename = "${path.module}/inventory"
}
