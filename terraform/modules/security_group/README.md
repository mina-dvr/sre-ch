# Security group module

This module creates a security group and its rules with `arvan_security_group`. The output ID is used to attach the group to instances.

## Provider

The module needs the local provider name `arvan`, source `terraform.arvancloud.ir/arvancloud/iaas`, version `0.8.1`. Authentication is configured in the root module.

## Inputs

| Name | Type | Purpose |
| --- | --- | --- |
| `region` | `string` | Arvan region |
| `name` | `string` | Group name |
| `description` | `string` | Group description |
| `rules` | `list(object)` | Firewall rules; `direction` is `ingress` or `egress`, `protocol` is required (use `tcp`, `udp`, or `icmp`), and `ip` must be a CIDR when set |

Example rule:

```hcl
{
  direction   = "ingress"
  protocol    = "tcp"
  port_from   = "22"
  port_to     = "22"
  ip          = "0.0.0.0/0"
  description = "SSH"
}
```

## Output

| Name | Value |
| --- | --- |
| `id` | Group ID for the instance `security_groups` argument |

After a successful deploy, add this block to the group resource to block accidental deletion:

```hcl
lifecycle {
  prevent_destroy = true
}
```

See the [production environment](../../environments/production/README.md) for a full example.
