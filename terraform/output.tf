
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    public_ips = resource.warren_floating_ip.denvr_ip,
    vms = resource.warren_virtual_machine.denvr_vms
  })
  filename = "${path.module}/inventory"
}
