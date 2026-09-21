output "instances" {
  description = "Internet IPv4 (enable_ipv4) and private-network IPv4, keyed by instance name. Floating IPs are not used."
  value = {
    for name, instance in module.instance : name => {
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  }
}
