locals {
  gateway_ips    = var.gateway_ip == null || try(trimspace(var.gateway_ip), "") == "" ? [] : [var.gateway_ip]
  dhcp_ips       = var.dhcp_range == null ? [] : [var.dhcp_range.start, var.dhcp_range.end]
  network_prefix = split("/", var.cidr)[1]

  ipv4_in_cidr = {
    for ip in concat(local.dhcp_ips, local.gateway_ips) : ip => (
      cidrhost("${ip}/${local.network_prefix}", 0) == cidrhost(var.cidr, 0)
    )
  }

  ipv4_number = {
    for ip in concat(local.dhcp_ips, local.gateway_ips) : ip => (
      parseint(split(".", ip)[0], 10) * 16777216 +
      parseint(split(".", ip)[1], 10) * 65536 +
      parseint(split(".", ip)[2], 10) * 256 +
      parseint(split(".", ip)[3], 10)
    )
  }

  dhcp_range_present = var.dhcp_range != null
  dhcp_in_cidr = !var.enable_dhcp || (
    local.dhcp_range_present &&
    local.ipv4_in_cidr[var.dhcp_range.start] &&
    local.ipv4_in_cidr[var.dhcp_range.end]
  )
  dhcp_order_valid = !var.enable_dhcp || (
    local.dhcp_range_present &&
    local.ipv4_number[var.dhcp_range.start] <= local.ipv4_number[var.dhcp_range.end]
  )

  gateway_outside_dhcp = length(local.gateway_ips) == 0 || !local.dhcp_range_present ? true : (
    local.ipv4_number[local.gateway_ips[0]] < local.ipv4_number[var.dhcp_range.start] ||
    local.ipv4_number[local.gateway_ips[0]] > local.ipv4_number[var.dhcp_range.end]
  )

  gateway_valid = !var.enable_gateway || (
    try(local.ipv4_in_cidr[var.gateway_ip], false) &&
    (!var.enable_dhcp || local.gateway_outside_dhcp)
  )
}
