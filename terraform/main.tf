
data "warren_network" "public" {
  name = "default" # Edit it with yours
}

resource "warren_floating_ip" "ingress" {
  count = "${var.vm_number}"
  name = "ip-${var.vm_prefix}-${count.index}"
}


# Resources managed by Terraform
resource "warren_virtual_machine" "warren_test" {
    count = "${var.vm_number}"
    disk_size_in_gb = "${var.disk_size}"
    memory          = "${var.ram_number}"
    name            = "${var.vm_prefix}-${count.index}"
    username        = "${var.username}"
    os_name         = "${var.os_name}"
    os_version      = "${var.os_version}"
    vcpu            = "${var.cpu_number}"
    network_uuid = data.warren_network.public.id
    reserve_public_ip = true
    public_key = "${var.ssh_public_key}"
}
