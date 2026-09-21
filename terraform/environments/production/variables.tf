variable "api_key" {
  description = "ArvanCloud API key"
  type        = string
  sensitive   = true
}

variable "instances" {
  description = "Instances to create, keyed by unique name. Omit private_ip to let DHCP assign the address."
  type = map(object({
    private_ip  = optional(string)
    enable_ipv4 = optional(bool, true)
  }))

  validation {
    condition     = length(var.instances) > 0
    error_message = "At least one instance is required."
  }

  validation {
    condition = alltrue([
      for instance in var.instances : instance.private_ip == null || can(cidrnetmask("${instance.private_ip}/32"))
    ])
    error_message = "Each instance private_ip must be a valid IPv4 address."
  }

  validation {
    condition = length([
      for instance in var.instances : instance.private_ip if instance.private_ip != null
      ]) == length(distinct([
        for instance in var.instances : instance.private_ip if instance.private_ip != null
    ]))
    error_message = "instance private_ip values must be unique."
  }

  validation {
    condition = var.gateway_ip == null || try(trimspace(var.gateway_ip), "") == "" || alltrue([
      for instance in var.instances : instance.private_ip == null || instance.private_ip != var.gateway_ip
    ])
    error_message = "An instance private_ip must not reuse gateway_ip."
  }
}

variable "instance_plan" {
  description = "Name of the ArvanCloud plan"
  type        = string
}

variable "instance_disk_size" {
  description = "Root disk size in GB for each instance"
  type        = number
}

variable "instance_ssh_key_name" {
  description = "Existing SSH key name shared by the instances"
  type        = string
}

variable "instance_image_distro" {
  description = "Image distro_name to select from arvan_images"
  type        = string
}

variable "instance_image_release" {
  description = "Image name/release to select from arvan_images, for example 22.04"
  type        = string
}

variable "region" {
  description = "ArvanCloud region"
  type        = string
}

variable "network_name" {
  description = "Private network name"
  type        = string
}

variable "network_description" {
  description = "Private network description"
  type        = string
}

variable "dhcp_range" {
  description = "DHCP IP address range; required only when enable_dhcp is true"

  type = object({
    start = string
    end   = string
  })
  default = null
}

variable "dns_servers" {
  description = "DHCP DNS servers; required when enable_dhcp is true"
  type        = list(string)
  default     = []
}

variable "enable_dhcp" {
  description = "Enable DHCP on the private network"
  type        = bool
}

variable "enable_gateway" {
  description = "Enable gateway on the private network"
  type        = bool
}

variable "network_cidr" {
  description = "CIDR of the private network"
  type        = string
}

variable "gateway_ip" {
  description = "Gateway IP address; required only when enable_gateway is true"
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "Name of the Terraform-managed security group"
  type        = string
}

variable "security_group_description" {
  description = "Description of the Terraform-managed security group"
  type        = string
}

