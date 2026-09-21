output "resource_id" {
  description = "ID used by the provider to manage the private network resource"
  value       = arvan_network.private_network.id
}

output "network_id" {
  description = "Network ID used when attaching instances"
  value       = arvan_network.private_network.network_id
}
