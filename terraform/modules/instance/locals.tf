locals {
  network_prefix = split("/", var.network_cidr)[1]
  dhcp_ips       = var.dhcp_range == null ? [] : [var.dhcp_range.start, var.dhcp_range.end]
  known_ips      = compact(concat(var.private_ip == null ? [] : [var.private_ip], local.dhcp_ips))

  ipv4_in_cidr = {
    for ip in local.known_ips : ip => cidrhost("${ip}/${local.network_prefix}", 0) == cidrhost(var.network_cidr, 0)
  }

  ipv4_number = {
    for ip in local.known_ips : ip => (
      parseint(split(".", ip)[0], 10) * 16777216 +
      parseint(split(".", ip)[1], 10) * 65536 +
      parseint(split(".", ip)[2], 10) * 256 +
      parseint(split(".", ip)[3], 10)
    )
  }

  private_ip_in_cidr = var.private_ip == null || try(local.ipv4_in_cidr[var.private_ip], false)

  private_ip_outside_dhcp = var.private_ip == null || var.dhcp_range == null || (
    local.ipv4_number[var.private_ip] < local.ipv4_number[var.dhcp_range.start] ||
    local.ipv4_number[var.private_ip] > local.ipv4_number[var.dhcp_range.end]
  )
}
