# ntp

Installs chrony, writes `/etc/chrony/chrony.conf` from the server list, and enables the service. `prepare.yml` runs it before SSH hardening. Kubespray NTP is disabled in group_vars (`ntp_enabled: false`) so this role stays the source of time sync.

## Variables

| Name | Type | Purpose |
| --- | --- | --- |
| `ntp_servers` | `list` | NTP servers written into chrony.conf, one `server … iburst` line each |

There is no role default for `ntp_servers`. Production sets `time.cloudflare.com` and `ntp.ubuntu.com` in `inventory/production/group_vars/all.yml`. Outbound UDP/123 must be open from the nodes.
