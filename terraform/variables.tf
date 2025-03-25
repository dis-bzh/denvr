
variable "api_token" {
  description = "API token for the Warren provider"
  type        = string
}

variable "prefix" {
  description = "Prefix for VMs name"
  default     = "denvr"
}

variable "ssh_public_key" {
  description = "public SSH key name for the instances"
  type        = string
}

variable "username" {
  description = "Username for the instances"
  type        = string
}

variable "os_name" {
  description = "Name of the OS for the instances"
  type        = string
}

variable "os_version" {
  description = "Version of the OS for the instances"
  type        = string
}

# variable "vm_number" {
#   description = "Number of instances to manage"
#   type        = number
# }

# variable "cpu_number" {
#   description = "Number of vCPU for the instances"
#   type        = number
# }

# variable "ram_number" {
#   description = "Number of RAM for the instances"
#   type        = number
# }

# variable "disk_size" {
#   description = "Number of RAM for the instances"
#   type        = number
# }

variable "vms" {
  description = "Details of VMs"
  type        = list(object({
    name = string
    cpu_number = number
    ram_number = number
    disk_size = number
    network = string
  }))
}

variable "networks_names" {
  description = "Names of the networks to connect created VMs"
  type        = list(string)
}