# user_management

Creates operator users and groups, installs each user's SSH public key, and grants passwordless sudo to the sudo group. `prepare.yml` runs this first.

## Variables

| Name | Type | Purpose |
| --- | --- | --- |
| `user_management_groups` | `list` | Groups to create, for example `infra` |
| `user_management_sudo_group` | `string` | Group that receives NOPASSWD sudo |
| `user_management_users` | `list` of objects | Users to create. Each item has `username`, optional `groups`, `shell`, `state`, and `ssh_key` |

Existing authorized keys are not removed. The sudoers file is checked with `visudo` before it is installed.

Production values live in `inventory/production/group_vars/all.yml`. The public key is set on each user as `ssh_key`.
