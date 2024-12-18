
variable "api_token" {
  description = "API token for the Warren provider"
  type        = string
}

variable "vm_prefix" {
  description = "Prefix for VM name"
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

variable "vm_number" {
  description = "Number of instances to manage"
  type        = number
}

variable "cpu_number" {
  description = "Number of vCPU for the instances"
  type        = number
}

variable "ram_number" {
  description = "Number of RAM for the instances"
  type        = number
}

variable "disk_size" {
  description = "Number of RAM for the instances"
  type        = number
}

variable "network_name" {
  description = "Name of the network to connect created VMs"
  type        = string
}