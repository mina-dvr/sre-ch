# monitoring

Installs Prometheus, Grafana, and Alertmanager with the pinned Helm chart `kube-prometheus-stack` on the first control-plane node. Run it after `playbooks/cluster.yml` so Helm, `local-path`, and ingress-nginx already exist.

```bash
cd ansible
ansible-galaxy collection install -r collections/requirements.yml -p collections
ansible-playbook playbooks/monitoring.yml --ask-vault-pass
```

`grafana_password` in `inventory/production/group_vars/k8s_cluster/vault.yml` is passed to Helm as `grafana.adminPassword`. That is the Grafana login on first start.

The chart scrapes node-exporter, kube-state-metrics, kubelet, API server, and CoreDNS. etcd scraping is off.

`files/alerts/*.yml` is applied as `PrometheusRule` objects after Helm. `nodes.yml` fires when a node stays above 80% CPU or 85% memory for 10 minutes, or 85% disk for 15 minutes. See Alertmanager at `a.mina-dvr.ir`.

Alerts route to Telegram. `telegram_bot_token` and a numeric `telegram_chat_id` live in `group_vars/k8s_cluster/vault.yml`. Grafana's admin password is set only on first start; later Helm runs do not reset it.

TLS stays on the CDN. Origin is HTTP on port 80. Hosts are `g.mina-dvr.ir`, `p.mina-dvr.ir`, and `a.mina-dvr.ir`.
