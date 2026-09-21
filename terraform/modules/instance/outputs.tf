output "id" {
  description = "ID of the created instance"
  value       = arvan_abrak.this.id
}

output "private_ip" {
  description = "IPv4 on the private cluster network"
  value = one([
    for network in arvan_abrak.this.networks : network.ip
    if try(network.is_public, false) == false && try(network.ip, "") != ""
  ])
}

output "public_ip" {
  description = "Internet IPv4 from enable_ipv4. This is not a floating IP."
  value = one([
    for network in arvan_abrak.this.networks : network.ip
    if try(network.is_public, false) && try(network.ip, "") != ""
  ])
}
