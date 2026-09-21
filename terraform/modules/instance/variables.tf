variable "region" {
  description = "ArvanCloud region"
  type        = string
}

variable "name" {
  description = "Instance name"
  type        = string
}

variable "image_id" {
  description = "Operating system image ID in the selected region"
  type        = string
}

variable "flavor_id" {
  description = "Plan ID in the selected region"
  type        = string
}

variable "disk_size" {
  description = "Root disk size in GB"
  type        = number

  validation {
    condition     = var.disk_size > 0 && floor(var.disk_size) == var.disk_size
    error_message = "disk_size must be a positive integer in GB."
  }
}

variable "image_min_disk" {
  description = "Minimum disk size required by the selected image, in GB"
  type        = number

  validation {
    condition     = var.image_min_disk >= 0
    error_message = "image_min_disk must be zero or a positive number of GB."
  }
}

variable "ssh_key_name" {
  description = "Name of an existing ArvanCloud SSH key"
  type        = string
}

variable "network_id" {
  description = "Private network ID (not the subnet ID)"
  type        = string
}

variable "network_cidr" {
  description = "CIDR of the private network used to validate a static private_ip"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.network_cidr))
    error_message = "network_cidr must be a valid IPv4 CIDR."
  }
}

variable "dhcp_range" {
  description = "DHCP pool that a static private_ip must stay outside; required only when DHCP is enabled"

  type = object({
    start = string
    end   = string
  })
  default = null

  validation {
    condition = var.dhcp_range == null || (
      can(cidrnetmask("${var.dhcp_range.start}/32")) &&
      can(cidrnetmask("${var.dhcp_range.end}/32"))
    )
    error_message = "dhcp_range.start and dhcp_range.end must be valid IPv4 addresses."
  }
}

variable "private_ip" {
  description = "Optional static private IPv4. Leave null to let DHCP assign the address."
  type        = string
  default     = null

  validation {
    condition     = var.private_ip == null || can(cidrnetmask("${var.private_ip}/32"))
    error_message = "private_ip must be a valid IPv4 address."
  }
}

variable "enable_ipv4" {
  description = "Allocate an internet IPv4 (not a floating IP). Only settable at creation time."
  type        = bool
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the instance"
  type        = set(string)
}
