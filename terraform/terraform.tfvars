
prefix = "vde"
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeFbFAXm1hKy++2RAV0RtCbHIX5y0WlYSKKxv+cFNwC vde@TUF-0126"
username = "ansible"
os_name = "ubuntu"
os_version = "24.04"

networks_names = ["internal-network"]

vms = [
    {
        name = "bastion"
        cpu_number = 1
        ram_number = 1024
        disk_size = 20
        network = "internal-network"
        public_ip = true
    },
    {
        name = "app"
        cpu_number = 1
        ram_number = 1024
        disk_size = 20
        network = "internal-network"
        public_ip = true
    },
    {
        name = "monitoring"
        cpu_number = 2
        ram_number = 2048
        disk_size = 20
        network = "internal-network"
        public_ip = true
    }
]