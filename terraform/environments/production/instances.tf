data "arvan_images" "ubuntu" {
  region     = var.region
  image_type = "distributions"
}

data "arvan_plans" "available" {
  region = var.region
}

data "arvan_ssh_keys" "available" {
  region = var.region
}

module "instance" {
  for_each = var.instances
  source   = "../../modules/instance"

  region             = var.region
  name               = each.key
  image_id           = local.selected_image.id
  flavor_id          = local.selected_plan.id
  disk_size          = var.instance_disk_size
  image_min_disk     = local.selected_image.disk
  ssh_key_name       = var.instance_ssh_key_name
  network_id         = module.private_network.network_id
  network_cidr       = var.network_cidr
  dhcp_range         = var.enable_dhcp ? var.dhcp_range : null
  private_ip         = each.value.private_ip
  enable_ipv4        = each.value.enable_ipv4
  security_group_ids = each.value.enable_ipv4 ? toset([module.security_group.id]) : toset([])
}
