
# Resources managed by Terraform

# Network
resource "warren_network" "public" {
  name = "${var.network_name}"
}

# VMs
resource "warren_virtual_machine" "denvr_vm" {
    count = "${var.vm_number}"
    disk_size_in_gb = "${var.disk_size}"
    memory          = "${var.ram_number}"
    name            = "${var.vm_prefix}-${count.index}"
    username        = "${var.username}"
    os_name         = "${var.os_name}"
    os_version      = "${var.os_version}"
    vcpu            = "${var.cpu_number}"
    network_uuid = resource.warren_network.public.id
    reserve_public_ip = false # if true, we can't retrieve the IP with Terraform
    public_key = "${var.ssh_public_key}"
}

# IPs associated to VMs
resource "warren_floating_ip" "denvr_ip" {
  count = "${var.vm_number}"
  name = "ip-${var.vm_prefix}-${count.index}"
  assigned_to = resource.warren_virtual_machine.denvr_vm[count.index].id
}
