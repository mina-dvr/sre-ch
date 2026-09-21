# Ansible and Kubernetes

This directory prepares Ubuntu (package updates, the `mina` user, SSH hardening, and NTP with chrony) and then installs Kubernetes with Kubespray. Docker is installed by `cluster.yml`, not by the prepare playbook.

## Layout

```text
Pipfile                 dependencies aligned with Kubespray v2.29.1
inventory/production/
  hosts.ini             groups and node names only
  host_vars/k1.yml      node IPs; k2 and k3 are the same shape
  group_vars/           shared settings
roles/
  user_management/      # operator users, keys, sudo
  packages/             # apt upgrade and base packages
  ntp/                  # chrony
  ssh_hardening/        # sshd policy
  monitoring/           # Prometheus, Grafana, Alertmanager
  postgresql/           # CloudNativePG operator and cluster
playbooks/prepare.yml   # OS prepare
playbooks/cluster.yml   # Kubernetes install via Kubespray
playbooks/monitoring.yml  # Prometheus, Grafana, Alertmanager
playbooks/postgresql.yml  # PostgreSQL cluster
scripts/sync_inventory.py
kubespray/              pinned Git submodule
docs/                   install-method comparison and rationale
```

All three nodes are control-plane, etcd, and worker. Applications run on the same three machines.

## 1. Runtime with Pipenv

Run from Linux or WSL with Python 3.10 (including 3.10.12) and OpenSSH. A native Windows Ansible controller is not supported. In WSL, keep the clone on the Linux filesystem so permissions and `ansible.cfg` discovery work.

Do not use the distro `pipenv` from apt (`/usr/bin/pipenv`). Ubuntu's package is too old (for example 11.9.0) and crashes on Python 3.10 with `collections.MutableMapping`. Install a current Pipenv with pip, put `~/.local/bin` on `PATH`, and invoke it as `python3.10 -m pipenv`.

From the repository root:

```bash
git submodule update --init --recursive
cd ansible
python3.10 -m pip install --user pipenv
python3.10 -m pipenv --version   # must not be 11.x
python3.10 -m pipenv install && python3.10 -m pipenv shell
ansible-galaxy collection install -r collections/requirements.yml -p collections
```

Vault-encrypted vars live in `inventory/production/group_vars/k8s_cluster/vault.yml`. Any playbook that touches `k8s_cluster` (including `prepare.yml` and `cluster.yml`) needs `--ask-vault-pass`.

Direct dependencies are pinned to `kubespray/requirements.txt` and locked in `Pipfile.lock`. After the first install, use `pipenv sync`.

## 2. Sync real IPs into host_vars

Private IPs for k1, k2, and k3 live in `inventory/production/host_vars`. After a Terraform apply, or whenever DHCP addresses change, refresh them from the machine that has Terraform state:

```bash
python scripts/sync_inventory.py
```

The script reads only `terraform output -json instances` and writes each node's `private_ip` to `ansible_host`, `ip`, and `access_ip`. Other host_vars are kept, and the main inventory stays uncluttered.

If state lives on another system, copy only the instances output:

```bash
terraform output -json instances > instances.json
# on the controller, from the ansible directory:
python scripts/sync_inventory.py --output-json /path/to/instances.json
```

The full Terraform state or a complete sensitive output is not required. IP changes need another sync. Review host_vars diffs and commit them if you want.

The controller must reach the private IPs over VPN, routing, or the same network. A public IP on the VM does not provide that path by itself. This guide assumes a direct private path.

## 3. SSH key and bootstrap
The private key is not in the repo. SSH to all three private IPs and compare fingerprints with a trusted source so `known_hosts` is populated. The images log in as `root` with the Arvan key named `mina2`; the Linux user `mina` does not exist until `prepare.yml` creates it.

```bash
ansible-inventory --graph
ansible k8s_cluster -m ping
ansible-playbook playbooks/prepare.yml --ask-vault-pass
```

SSH hardening runs last. Password and keyboard-interactive authentication are disabled. Root pubkey login stays enabled. The config is checked with `sshd -t`. The SSH port is not changed.

If a host key changes after a VM rebuild, confirm the change first, then update `known_hosts`. If you use a bastion, put ProxyJump in `~/.ssh/config` for the private IPs so both Ansible and the fresh SSH check use it.

## 4. Packages and NTP

The packages role refreshes the apt index, upgrades installed packages with `safe`, and reboots the node if `/var/run/reboot-required` is present. chrony syncs time, and `ntp_enabled: false` stops Kubespray from managing NTP again. Outbound access to Ubuntu mirrors and UDP/123 is required.

Role details:

- [user_management](roles/user_management/README.md)
- [packages](roles/packages/README.md)
- [ntp](roles/ntp/README.md)
- [ssh_hardening](roles/ssh_hardening/README.md)
- [monitoring](roles/monitoring/README.md)
- [postgresql](roles/postgresql/README.md)

## 5. Install Kubernetes

After `prepare.yml`, install the cluster with the playbook in `playbooks/`:

```bash
ansible-playbook playbooks/cluster.yml --ask-vault-pass
```

That file imports the pinned Kubespray v2.29.1 `cluster.yml`. Docker, cri-dockerd, Calico, Helm, local-path provisioner, and ingress-nginx come from that release. All three nodes are control-plane and worker; the no-schedule taint is not left in place. `download_run_once` pulls container images on k1 and copies them to k2 and k3 so a 403 from `registry.k8s.io` on one public IP does not stop the install.

`admin.conf` on the nodes is sensitive; do not commit it.

## 6. Monitoring

After the cluster is up, install Prometheus, Grafana, and Alertmanager:

```bash
ansible-playbook playbooks/monitoring.yml --ask-vault-pass
```

The stack uses kube-prometheus-stack with small PVCs on `local-path`. Hosts are `g.mina-dvr.ir` (Grafana), `p.mina-dvr.ir` (Prometheus), and `a.mina-dvr.ir` (Alertmanager). TLS stays on the CDN; origin HTTP is port 80. Grafana's admin password is `grafana_password` in `group_vars/k8s_cluster/vault.yml` (first start only). Alerts go to Telegram from `telegram_bot_token` and numeric `telegram_chat_id` in the same vault file. Extra rules are in `roles/monitoring/files/alerts/*.yml`. See the [monitoring role](roles/monitoring/README.md).

## 7. PostgreSQL

After the cluster (and preferably monitoring) is up:

```bash
ansible-playbook playbooks/postgresql.yml --ask-vault-pass
```

CloudNativePG runs three PostgreSQL 16 instances on `local-path`. App user `mina` / database `mina`. Passwords are `postgres_superuser_password` and `postgres_app_password` in `group_vars/k8s_cluster/vault.yml`. The write service is `mina-pg-rw.postgres.svc:5432`. S3 credentials are in the vault but cluster backups are not enabled yet. See the [postgresql role](roles/postgresql/README.md).

## Tool choice

The [comparison of kubeadm, Kubespray, K3s, RKE2, MicroK8s, Talos, and managed Kubernetes](docs/kubernetes-installation.md) explains why Kubespray was chosen and the limits of a three-node topology.
