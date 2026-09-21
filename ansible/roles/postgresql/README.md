# postgresql

Installs the CloudNativePG operator and a three-instance PostgreSQL 16 cluster on the first control-plane node with `kubernetes.core` (`helm`, `k8s`, `k8s_info`). Run it after `playbooks/cluster.yml`. Run `playbooks/monitoring.yml` first if `postgresql_monitoring` is true (PodMonitor).

```bash
cd ansible
ansible-playbook playbooks/postgresql.yml --ask-vault-pass
```

Vault keys in `inventory/production/group_vars/k8s_cluster/vault.yml`:

- `postgres_superuser_password` — user `postgres`
- `postgres_app_password` — user `mina`, database `mina`
- `s3_backup_access_key` / `s3_backup_secret_key` — reserved for Arvan S3; the cluster chart currently has `backups.enabled: false`

The cluster is `mina-pg` in namespace `postgres`. Storage is `local-path` (5Gi per instance, one PVC per node). Service `mina-pg-rw` is the primary (write); `mina-pg-ro` is read replicas. ClusterIP only; do not put Postgres on the CDN.

From a pod in the cluster:

```text
host: mina-pg-rw.postgres.svc
port: 5432
user: mina
dbname: mina
```
