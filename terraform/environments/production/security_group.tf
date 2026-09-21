module "security_group" {
  source = "../../modules/security_group"

  region      = var.region
  name        = var.security_group_name
  description = var.security_group_description
  rules       = local.security_group_rules
}
