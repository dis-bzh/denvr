
data "warren_network" "public" {
  name = "default" # Edit it with yours
}

# Resources managed by Terraform
resource "warren_virtual_machine" "warren_test" {
    count = 1
    disk_size_in_gb = 10
    memory          = 512
    name            = "warren-test-${count.index}"
    username        = "user" # Edit it
    os_name         = "ubuntu"
    os_version      = "22.04"
    vcpu            = 1
    network_uuid = data.warren_network.public.id
    reserve_public_ip = true
    # public_key = "ssh-ed25519 AAAAxxxXXX myUsername@denvr" # Edit it
}
