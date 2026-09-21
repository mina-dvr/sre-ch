resource "arvan_abrak" "this" {
  region          = var.region
  name            = var.name
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  disk_size       = var.disk_size
  ssh_key_name    = var.ssh_key_name
  enable_ipv4     = var.enable_ipv4
  enable_ipv6     = false
  security_groups = var.security_group_ids

  networks = [{
    network_id = var.network_id
    ip         = var.private_ip
  }]

  lifecycle {
    precondition {
      condition     = length(trimspace(var.image_id)) > 0
      error_message = "image_id must be a resolved image identifier."
    }

    precondition {
      condition     = length(trimspace(var.flavor_id)) > 0
      error_message = "flavor_id must be a resolved plan identifier."
    }

    precondition {
      condition     = var.disk_size >= var.image_min_disk
      error_message = "The selected image requires at least ${var.image_min_disk} GB; disk_size is ${var.disk_size}."
    }

    precondition {
      condition     = local.private_ip_in_cidr
      error_message = "private_ip ${coalesce(var.private_ip, "(none)")} must be inside ${var.network_cidr}."
    }

    precondition {
      condition     = local.private_ip_outside_dhcp
      error_message = "private_ip ${coalesce(var.private_ip, "(none)")} must be outside DHCP range ${try("${var.dhcp_range.start}-${var.dhcp_range.end}", "unset")}."
    }
  }
}
