
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    public_ips = warren_virtual_machine.warren_test.*.reserve_public_ip
  })
  filename = "${path.module}/inventory.ini"
}

output "server_ips" {
  value = warren_virtual_machine.warren_test.*.reserve_public_ip
}
