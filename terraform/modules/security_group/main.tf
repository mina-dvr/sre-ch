resource "arvan_security_group" "this" {
  region      = var.region
  name        = var.name
  description = var.description
  rules       = var.rules
}
