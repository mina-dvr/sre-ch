check "instance_image" {
  assert {
    condition     = length(local.ubuntu_images) == 1
    error_message = "Expected exactly one ${var.instance_image_distro} ${var.instance_image_release} image; found ${length(local.ubuntu_images)} matches. Available images: ${jsonencode([for image in data.arvan_images.ubuntu.distributions : { id = image.id, name = image.name, distro_name = image.distro_name }])}"
  }
}

check "instance_plan" {
  assert {
    condition     = length(local.instance_plans) == 1
    error_message = "Expected exactly one plan named ${var.instance_plan} in this region. Check arvan_plans."
  }
}

check "instance_ssh_key" {
  assert {
    condition     = contains([for key in data.arvan_ssh_keys.available.keys : key.name], var.instance_ssh_key_name)
    error_message = "SSH key ${var.instance_ssh_key_name} was not found in this region."
  }
}
