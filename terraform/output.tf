
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    public_ips = warren_floating_ip.ingress.*.public_ipv6
  })
  filename = "${path.module}/inventory"
}
