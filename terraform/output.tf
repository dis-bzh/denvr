output "vms" {
  value     = resource.warren_virtual_machine.denvr_vms
  sensitive = true
}

output "public_ips" {
  value = resource.warren_floating_ip.denvr_ip
}
