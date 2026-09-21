# Production environment

This directory is the production Terraform root. Run Terraform from here.

## Files

| File | Purpose |
| --- | --- |
| `terraform.tfvars` | Production values |
| `backend.tf` | Remote state for production (`production/terraform.tfstate`) |
| `*.tf` | Root-module code |
| `.terraform.lock.hcl` | Provider lockfile |

To add staging or develop, copy this directory, change the state `key` in `backend.tf` and the values in `terraform.tfvars`, then run Terraform from that new directory.

Environment variable names are independent of module inputs. For example, this environment's `network_name` is passed as `name = var.network_name`.

## Inputs

All inputs except `gateway_ip` are required. `gateway_ip` defaults to `null` and is required only when the gateway is enabled. `enable_ipv4` defaults to `true` on each instance.

| Name | Type | Purpose |
| --- | --- | --- |
| `api_key` | `string`, sensitive | ArvanCloud API key |
| `region` | `string` | Network region |
| `network_name` | `string` | Network name |
| `network_description` | `string` | Network description |
| `network_cidr` | `string` | Network CIDR |
| `gateway_ip` | `string` | Gateway address; required only when `enable_gateway = true` |
| `dhcp_range` | `object({ start = string, end = string })` | DHCP start and end |
| `dns_servers` | `list(string)` | DHCP DNS servers; required when `enable_dhcp = true` |
| `enable_dhcp` | `bool` | Enable DHCP |
| `enable_gateway` | `bool` | Enable the gateway |
| `instances` | `map(object)` | Instances with optional `enable_ipv4` and `private_ip`; omit `private_ip` to use DHCP |
| `instance_plan` | `string` | Shared plan name |
| `instance_disk_size` | `number` | Disk size per instance, in GB |
| `instance_ssh_key_name` | `string` | Existing SSH key name |
| `instance_image_distro` | `string` | Image distro name, for example `ubuntu` |
| `instance_image_release` | `string` | Image release, for example `22.04` |
| `security_group_name` | `string` | Created security group name |
| `security_group_description` | `string` | Security group description |

Current network values in `terraform.tfvars`:

```hcl
region              = "eu-west1-a"
network_name        = "tf_private_network"
network_description = "Terraform-created private network"
network_cidr        = "192.168.110.0/24"

dhcp_range = {
  start = "192.168.110.20"
  end   = "192.168.110.50"
}

dns_servers    = ["8.8.8.8", "1.1.1.1"]
enable_dhcp    = true
enable_gateway = false
```

## Run

Run the following from this directory. See the [root README](../../../README.md) for prerequisites.

Set the key in the environment; do not put it in `terraform.tfvars`. `*.secret.tfvars` files are ignored.

```powershell
$env:TF_VAR_api_key = "apikey <YOUR_API_KEY>"
terraform init
terraform validate
terraform plan
```

After reviewing the plan:

```powershell
terraform apply
terraform output instances
```

The `instances` output is each node's public and private address. This configuration creates the network and machines; it does not install Kubernetes.

## Three instances

Current `terraform.tfvars` values:

```hcl
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
```

Each instance has three distinct address concepts. Floating IPs are not used:

- **Internet IP:** allocated at create time with `enable_ipv4 = true`. From the internet, only `22` / `80` / `443` are open.
- **Private network:** DHCP on `192.168.110.0/24`. Cluster traffic uses this path. On Arvan the security group applies to the whole instance, so the private CIDR is also allowed.
- **Floating IP:** not used and not defined here.

IPv6 is disabled. `enable_ipv4` can only be changed at instance creation; an existing node must be rebuilt.

Private addresses are not hardcoded. DHCP assigns them and the `instances` output reports them. After apply, run `scripts/sync_inventory.py` to refresh the Ansible inventory.

The region's default security group is not used. Group `tf_k8s` is attached to the instance, not only to the internet IP. The provider rejects `port_security_enabled = false` on the private NIC and returns `true` after apply. Ports `22`, `80`, and `443` are open from the internet, and traffic inside the private CIDR is allowed separately so the cluster is not blocked. Egress is open.

At plan time, images, plans, and SSH keys are read from Arvan. The image is selected with `instance_image_distro` and `instance_image_release`. `checks.tf` requires exactly one matching image and plan, and that the SSH key exists. Disk, CIDR, DHCP, and gateway rules live on the modules, not again in this environment. If the real image name in the region differs, align the tfvars values with the Arvan catalog.

After a successful deploy and a stable cluster, add `prevent_destroy = true` to the network, security group, and instance `lifecycle` blocks so `terraform destroy` or an accidental removal in a plan cannot delete them. Do not add that lock before the first deploy, so testing and rebuilds stay easy.

A sample instance address in state is `module.instance["k1"].arvan_abrak.this`. `for_each` keeps identity stable if names are reordered; removing a name from the map requests deletion of that instance.

## State and dependencies

The S3 backend is defined in `backend.tf`:

- Existing bucket: `k8s-terraform`
- Endpoint: `https://s3.ir-thr-at1.arvanstorage.ir`
- State path: `production/terraform.tfstate`
- Object-storage region: `ir-thr-at1`, independent of the instance region.

Set the object-storage keys in the runner environment. They are different from the IaaS API key and are not stored in the repo.

```powershell
$env:AWS_ACCESS_KEY_ID = "<STORAGE_ACCESS_KEY>"
$env:AWS_SECRET_ACCESS_KEY = "<STORAGE_SECRET_KEY>"
```

On Linux/WSL:

```bash
export AWS_ACCESS_KEY_ID='<STORAGE_ACCESS_KEY>'
export AWS_SECRET_ACCESS_KEY='<STORAGE_SECRET_KEY>'
```

### Migrating existing state

Run this from this directory on the system that currently holds the network and instance state. Keep a local state backup outside Git first, and confirm the destination path is not another state's file.

```powershell
terraform init -migrate-state
terraform state list
terraform plan
```

Confirm the destination when prompted. Do not use `-reconfigure` instead of `-migrate-state`. After migration, the same resources should appear in state; a backend change alone should not propose rebuilding infrastructure.

On new controllers after migration, set only the object-storage keys and run `terraform init`. The Ansible IP sync script also needs this access to read remote state.

These settings do not enable state locking. Do not run write operations from more than one system at a time. S3 lockfile support depends on conditional writes on the Arvan endpoint. Enable bucket versioning in the panel so previous state versions can be recovered. Restrict access to state; it can contain sensitive data.

`.terraform.lock.hcl` records the selected provider version and checksums and must be kept in Git.
