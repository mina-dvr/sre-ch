variable "region" {
  description = "ArvanCloud region"
  type        = string
}

variable "name" {
  description = "Security group name"
  type        = string
}

variable "description" {
  description = "Security group description"
  type        = string
}

variable "rules" {
  description = "Firewall rules. Rule IPs must be CIDR values when set."

  type = list(object({
    direction   = string
    protocol    = string
    description = optional(string)
    ip          = optional(string)
    port_from   = optional(string)
    port_to     = optional(string)
  }))

  validation {
    condition = alltrue([
      for rule in var.rules : contains(["ingress", "egress"], rule.direction)
    ])
    error_message = "Each rule.direction must be ingress or egress."
  }

  validation {
    condition = alltrue([
      for rule in var.rules : contains(["tcp", "udp", "icmp"], rule.protocol)
    ])
    error_message = "Each rule.protocol must be tcp, udp, or icmp."
  }

  validation {
    condition = alltrue([
      for rule in var.rules : rule.ip == null || can(cidrnetmask(rule.ip))
    ])
    error_message = "Each rule.ip must be a valid CIDR, for example 192.168.110.0/24."
  }
}
