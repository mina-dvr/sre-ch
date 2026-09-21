module "private_network" {
  source = "../../modules/private_network"

  region      = var.region
  name        = var.network_name
  description = var.network_description

  cidr       = var.network_cidr
  gateway_ip = var.gateway_ip

  dhcp_range = var.enable_dhcp ? var.dhcp_range : null

  dns_servers = var.dns_servers

  enable_dhcp    = var.enable_dhcp
  enable_gateway = var.enable_gateway
}
