# Private network module

This module creates a private network on ArvanCloud with `arvan_network`. Settings include CIDR, gateway, DHCP, and DNS.

## Provider

The module needs the local provider name `arvan`, source `terraform.arvancloud.ir/arvancloud/iaas`, version `0.8.1`. Authentication is configured in the root module and inherited here.

## Example

The following is for a call from `terraform/environments/production` and assumes the provider is configured there.

```hcl
module "private_network" {
  source = "../../modules/private_network"

  region      = "eu-west1-a"
  name        = "tf_private_network"
  description = "Terraform-created private network"
  cidr        = "192.168.110.0/24"

  dhcp_range = {
    start = "192.168.110.20"
    end   = "192.168.110.50"
  }

  dns_servers    = ["8.8.8.8", "1.1.1.1"]
  enable_dhcp    = true
  enable_gateway = false
}

output "network_id" {
  value = module.private_network.network_id
}
```

## Inputs

`gateway_ip`, `dhcp_range`, and `dns_servers` are optional unless DHCP or the gateway is enabled. `gateway_ip` is required only when `enable_gateway = true`. `dhcp_range` and `dns_servers` are required only when `enable_dhcp = true`. The DHCP range must sit inside the CIDR, and start must not be greater than end. The Arvan provider requires DNS when DHCP is enabled.

| Name | Type | Purpose |
| --- | --- | --- |
| `region` | `string` | Arvan region |
| `name` | `string` | Network name |
| `description` | `string` | Network description |
| `cidr` | `string` | Network address range |
| `gateway_ip` | `string` | Gateway address; required only when `enable_gateway = true` |
| `dhcp_range` | `object({ start = string, end = string })` | DHCP range; required only when `enable_dhcp = true` |
| `dns_servers` | `list(string)` | DHCP DNS servers; required when `enable_dhcp = true` |
| `enable_dhcp` | `bool` | Enable DHCP |
| `enable_gateway` | `bool` | Enable the gateway |

The module validates `cidr`. If `dns_servers` is non-empty, each entry must be a valid IPv4 address. The DHCP range is checked only when DHCP is enabled. The gateway must be inside the subnet and, when DHCP is on, outside that range. When the gateway or DHCP is off, the related value is sent to the provider as `null`.

After a successful deploy, add this line to the network resource `lifecycle` to block accidental deletion:

```hcl
prevent_destroy = true
```

## Outputs

| Name | Value |
| --- | --- |
| `resource_id` | Provider resource ID from `arvan_network.private_network.id` |
| `network_id` | Network ID from `arvan_network.private_network.network_id`, used to attach instances |

Run this module from the [production environment](../../environments/production/README.md).
