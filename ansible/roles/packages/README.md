# packages

Refreshes apt, upgrades installed packages, installs the base tooling list, and removes unwanted packages. Unattended upgrades are turned off so package changes stay in this role. `prepare.yml` runs it after user creation and before NTP.

## Variables

| Name | Type | Purpose |
| --- | --- | --- |
| `packages_upgrade` | `string` | apt upgrade mode; production uses `safe` |
| `packages_base` | `list` | Packages to install |
| `packages_remove` | `list` | Packages to purge |

If `/var/run/reboot-required` exists after the upgrade, the role reboots the node (timeout 600 seconds) so a kernel update is applied before Kubernetes is installed.

Production values live in `inventory/production/group_vars/all.yml`.
