locals {
  ubuntu_images = [
    for image in data.arvan_images.ubuntu.distributions : image
    if lower(trimspace(image.distro_name)) == lower(trimspace(var.instance_image_distro)) && trimspace(image.name) == trimspace(var.instance_image_release)
  ]

  instance_plans = [
    for plan in data.arvan_plans.available.plans : plan
    if plan.name == var.instance_plan
  ]

  selected_image = one(local.ubuntu_images)
  selected_plan  = one(local.instance_plans)

  public_ingress_ports = ["22", "80", "443"]
  cluster_protocols    = ["tcp", "udp", "icmp"]

  security_group_rules = concat(
    [
      for port in local.public_ingress_ports : {
        direction   = "ingress"
        protocol    = "tcp"
        port_from   = port
        port_to     = port
        ip          = "0.0.0.0/0"
        description = "public ${port}"
      }
    ],
    [
      for protocol in local.cluster_protocols : {
        direction   = "ingress"
        protocol    = protocol
        ip          = var.network_cidr
        description = "private ${protocol}"
      }
    ],
    [
      for protocol in local.cluster_protocols : {
        direction   = "egress"
        protocol    = protocol
        description = "egress ${protocol}"
      }
    ]
  )
}
