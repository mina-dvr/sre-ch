# ArvanCloud Infrastructure as Code

This repository manages ArvanCloud infrastructure with Terraform. The production environment defines a private network, a dedicated security group, and three instances named `k1`, `k2`, and `k3` running Ubuntu 22.04 on the `std-medium3` plan with a 100 GB disk, DHCP private IPs, and internet IPv4. Ansible prepares the hosts and installs Kubernetes with Kubespray v2.29.1.

## Layout

```text
terraform/
  environments/production/  # production root module, tfvars, and backend
  modules/private_network/  # reusable private network module
  modules/security_group/   # cluster security group module
  modules/instance/         # instance module
ansible/                    # host prep, inventory, and Kubespray
```

## Prerequisites

- Terraform `1.16.2` or newer, as required by `environments/production/versions.tf`.
- Access to the `terraform.arvancloud.ir` registry to download the provider.
- An ArvanCloud API key that can manage networks in the target region.
- Provider `terraform.arvancloud.ir/arvancloud/iaas` version `0.8.1`, installed by `terraform init`.

## Getting started

Run commands from `terraform/environments/production`. Review the network values in `terraform.tfvars` first.

Set the API key from the environment:

`TF_VAR_api_key` is the IaaS API key. `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are the object-storage keys for the S3 backend in `backend.tf`. They are not the same credential.

```SHELL
export AWS_ACCESS_KEY_ID="<STORAGE_ACCESS_KEY>"
export AWS_SECRET_ACCESS_KEY="<STORAGE_SECRET_KEY>"
export TF_VAR_api_key="<YOUR_API_KEY>"
terraform init
terraform validate
terraform plan
```

Provide the IaaS API key from the environment only. Do not put it in `terraform.tfvars`. A value in the tfvars file overrides `TF_VAR_api_key`. `*.secret.tfvars` files are ignored. Do not commit a real key; rotate it if one was ever published.

After reviewing the plan, apply it:

```SHELL
terraform apply
```

## Formatting

From the repository root:

```SHELL
terraform fmt -check -recursive terraform
```

Use `terraform fmt -recursive terraform` to fix formatting.

## Docs

- [Production environment](terraform/environments/production/README.md)
- [Private network module](terraform/modules/private_network/README.md)
- [Security group module](terraform/modules/security_group/README.md)
- [Instance module](terraform/modules/instance/README.md)
- [Ansible and Kubernetes](ansible/README.md)
- [Kubernetes install options and why Kubespray](ansible/docs/kubernetes-installation.md)
