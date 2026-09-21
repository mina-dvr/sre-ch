variable "region" {
  description = "ArvanCloud region"
  type        = string
}

variable "name" {
  description = "Private network name"
  type        = string
}

variable "description" {
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

  validation {
    condition = var.dhcp_range == null || (
      can(cidrnetmask("${var.dhcp_range.start}/32")) &&
      can(cidrnetmask("${var.dhcp_range.end}/32"))
    )
    error_message = "dhcp_range.start and dhcp_range.end must be valid IPv4 addresses."
  }
}

variable "dns_servers" {
  description = "DHCP DNS servers. Required when enable_dhcp is true."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for dns in var.dns_servers : can(cidrnetmask("${dns}/32"))
    ])
    error_message = "Each dns_servers entry must be a valid IPv4 address."
  }
}

variable "enable_dhcp" {
  description = "Enable DHCP on the private network"
  type        = bool
}

variable "enable_gateway" {
  description = "Enable gateway on the private network"
  type        = bool
}

variable "cidr" {
  description = "CIDR of the private network"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "cidr must be a valid IPv4 CIDR, for example 192.168.110.0/24."
  }
}

variable "gateway_ip" {
  description = "Gateway IP address; required only when enable_gateway is true"
  type        = string
  default     = null
}
