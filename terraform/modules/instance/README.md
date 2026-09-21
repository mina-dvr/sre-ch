# Instance module

This module creates an instance with `arvan_abrak` and Arvan provider `0.8.1`. Production calls it with `for_each` to create three independent instances.

## Inputs

All inputs except `private_ip` and `dhcp_range` are required. `dhcp_range` is needed only when DHCP is enabled and `private_ip` is set.

| Name | Type | Purpose |
| --- | --- | --- |
| `region` | `string` | Arvan region |
| `name` | `string` | Instance name |
| `image_id` | `string` | Image ID in the region |
| `flavor_id` | `string` | Plan ID in the region |
| `disk_size` | `number` | Disk size in GB; positive integer |
| `image_min_disk` | `number` | Minimum disk required by the image, in GB |
| `ssh_key_name` | `string` | Existing SSH key name |
| `network_id` | `string` | Private network ID, not the subnet ID |
| `network_cidr` | `string` | Network CIDR used to validate a static IP |
| `dhcp_range` | `object({ start = string, end = string })` | Optional DHCP range that a static IP must stay outside |
| `private_ip` | `string` | Optional static private IPv4. If omitted, DHCP assigns the address |
| `enable_ipv4` | `bool` | Internet IPv4 (not a floating IP). Only settable at creation time |
| `security_group_ids` | `set(string)` | Instance security group IDs. The provider does not disable port security on the private NIC |

IPv6 is disabled in this module. The SSH key must already exist in Arvan. If `private_ip` is set, it must be inside the CIDR and outside the DHCP range. Production leaves it empty so DHCP assigns the address and `scripts/sync_inventory.py` reads the output for Ansible.

After a successful deploy, add this line to the `arvan_abrak` `lifecycle` block to block accidental deletion:

```hcl
prevent_destroy = true
```

## Outputs

- `id`: instance ID.
- `private_ip`: IPv4 on the private cluster network.
- `public_ip`: internet IPv4 from `enable_ipv4`. This is not a floating IP. It is empty if the address is not present on `networks`.

## Use in production

In the [production environment](../../environments/production/README.md), image and plan names are resolved to IDs from Arvan data sources. The instance attaches with the private network module's `network_id` output. `resource_id` is the provider's resource management ID.

Example with existing IDs:

```hcl
module "instance" {
  source = "../../modules/instance"

  region             = var.region
  name               = "k1"
  image_id           = var.image_id
  flavor_id          = var.flavor_id
  disk_size          = 100
  image_min_disk     = 25
  ssh_key_name       = "mina2"
  network_id         = module.private_network.network_id
  network_cidr       = "192.168.110.0/24"
  dhcp_range         = { start = "192.168.110.20", end = "192.168.110.50" }
  enable_ipv4        = true
  security_group_ids = var.security_group_ids
}
```

This example still needs root-module inputs and provider configuration. The full call is in `terraform/environments/production/instances.tf`.
