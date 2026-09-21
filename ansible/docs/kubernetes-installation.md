# Choosing a Kubernetes install method

## What this project needs

We have three Ubuntu 22.04 VMs on ArvanCloud. All three must be control-plane, etcd members, and application nodes. Infrastructure is created with Terraform and hosts are prepared with Ansible, so the install method must be reviewable, repeatable, and upgradeable with those same tools.

| Method | Strengths | Cost and limits | Fit for this project |
| --- | --- | --- | --- |
| kubeadm directly | Official bootstrap tool, a lot of control, good for learning | We would have to automate networking, HA, the runtime, upgrades, and OS settings ourselves | Viable, but needs more custom maintenance code |
| Kubespray | Ansible, uses kubeadm, multi-node and HA, ready roles for runtime and CNI, upgrade path | Many variables and dependencies, longer runs and more resources, must stay on compatible versions | Current choice; matches this repo's workflow |
| K3s | Simple and light, embedded etcd for HA, good for edge and small VMs | Different defaults and bundled components; you must decide what stays internal | Stronger if resource limits are the main constraint |
| RKE2 | Packaged distribution, HA, a defined security stance | Its own release cycle and settings | Worth considering for standardized enterprise needs |
| MicroK8s | Fast setup and addons, HA on a multi-node cluster | Depends on snap and its own management model | Fine for experiments and teams that want the Ubuntu ecosystem |
| Talos Linux | Immutable Kubernetes-focused OS, declarative management | Replaces Ubuntu; this project's SSH and user-management roles would not apply as they do now | Would require an infrastructure redesign |
| Managed service | Less control-plane operations work | Cost, provider limits, less control of masters | Does not match the request to manage these three VMs |
| kind / minikube | Good for local development and quick tests | Not aimed at a multi-machine production cluster | For local tests, not deploying these three VMs |

## Why Kubespray

This choice matches this repo: Ansible, keeping Ubuntu, three control-plane and etcd nodes, and repeatable operations without writing all bootstrap and upgrades in raw kubeadm. Kubespray does not replace kubeadm; it runs and coordinates many kubeadm steps.

Version `v2.29.1` is pinned as a Git submodule. Pipfile dependencies come from that version's `requirements.txt`. It works with Ansible 10.7.0 and the controller's Python 3.10. Kubernetes defaults in this release are 1.33.x. Newer Kubespray lines (2.31+) need ansible-core 2.18 and a newer Python. Change versions only after checking release notes and Python/Ansible requirements; do not auto-update the submodule to main.

## Topology and runtime

- k1, k2, and k3 are in `kube_control_plane`, `etcd`, and `kube_node`. For control-plane nodes that are also `kube_node` members, Kubespray removes the no-schedule taint.
- Three etcd members can survive losing one member. Running apps on the same machines competes for RAM, CPU, and I/O. The `std-medium3` plan name alone does not prove enough capacity; check real resources and Kubespray requirements before deploy.
- Docker is requested, so the runtime is `docker`. Kubespray installs `cri-dockerd`; Docker alone does not provide the CRI that current Kubernetes needs. `download_run_once: true` pulls images on k1 and copies them to the other nodes.
- Docker is installed in `cluster.yml`, not in the prepare playbook. If Docker is not required, containerd is a simpler runtime.
- Calico is the CNI. Compare Kubespray's default pod/service CIDRs with the private network, VPN, and organization networks before you run it.
- The API endpoint in Kubespray's internal HA is handled with local proxies. A stable external endpoint for users or CI is not defined at this stage; adding an LB/VIP is a separate decision.
- After the cluster is up, `playbooks/monitoring.yml` installs Prometheus, Grafana, and Alertmanager with kube-prometheus-stack. Public names are `g.mina-dvr.ir`, `p.mina-dvr.ir`, and `a.mina-dvr.ir`. TLS is on the CDN; the cluster origin is HTTP.
- `playbooks/postgresql.yml` installs CloudNativePG and a three-instance PostgreSQL cluster on `local-path`. It is ClusterIP only.

## Follow-up operations

Use the official `upgrade-cluster.yml` playbook and the pinned-version guide for upgrades. etcd backup and restore, resource requests/limits, and application availability policy belong in the operations phase. The OS prepare playbook is not a substitute for a cluster upgrade or coordinated drain/reboot.

## Sources

- https://kubespray.io/
- https://github.com/kubernetes-sigs/kubespray/tree/v2.29.1
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
- https://docs.k3s.io/
- https://docs.rke2.io/
- https://microk8s.io/docs
- https://www.talos.dev/
