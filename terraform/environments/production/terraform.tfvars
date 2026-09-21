region = "eu-west1-a"

instances = {
  k1 = { enable_ipv4 = true }
  k2 = { enable_ipv4 = true }
  k3 = { enable_ipv4 = true }
}

instance_plan          = "std-medium3"
instance_disk_size     = 100
instance_ssh_key_name  = "mina2"
instance_image_distro  = "ubuntu"
instance_image_release = "22.04"

network_name        = "tf_private_network"
network_description = "Terraform-created private network"

dhcp_range = {
  start = "192.168.110.20"
  end   = "192.168.110.50"
}

dns_servers = ["8.8.8.8", "1.1.1.1"]

enable_dhcp    = true
enable_gateway = false

network_cidr = "192.168.110.0/24"

security_group_name        = "tf_k8s"
security_group_description = "Internet SSH/HTTP/HTTPS and private cluster traffic"
