resource "arvan_network" "private_network" {
  region      = var.region
  description = var.description
  name        = var.name

  dhcp_range = var.enable_dhcp ? {
    start = var.dhcp_range.start
    end   = var.dhcp_range.end
  } : null

  dns_servers    = length(var.dns_servers) > 0 ? var.dns_servers : null
  enable_dhcp    = var.enable_dhcp
  enable_gateway = var.enable_gateway
  cidr           = var.cidr
  gateway_ip     = var.enable_gateway ? var.gateway_ip : null

  lifecycle {
    precondition {
      condition     = var.enable_gateway ? try(length(trimspace(var.gateway_ip)) > 0, false) : true
      error_message = "gateway_ip must be provided when enable_gateway is true."
    }

    precondition {
      condition     = !var.enable_dhcp || var.dhcp_range != null
      error_message = "dhcp_range must be provided when enable_dhcp is true."
    }

    precondition {
      condition     = !var.enable_dhcp || length(var.dns_servers) > 0
      error_message = "dns_servers must be set when enable_dhcp is true."
    }

    precondition {
      condition     = local.dhcp_in_cidr
      error_message = "dhcp_range.start and dhcp_range.end must be inside cidr."
    }

    precondition {
      condition     = local.dhcp_order_valid
      error_message = "dhcp_range.start must be less than or equal to dhcp_range.end."
    }

    precondition {
      condition     = local.gateway_valid
      error_message = "gateway_ip must be inside cidr and, when DHCP is enabled, outside the DHCP range."
    }
  }
}
