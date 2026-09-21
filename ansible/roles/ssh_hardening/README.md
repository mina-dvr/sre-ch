# ssh_hardening

Replaces `/etc/ssh/sshd_config` so password and keyboard-interactive logins are denied. Root pubkey login stays enabled. `prepare.yml` runs this last. The new file is validated with `sshd -t`, then ssh is reloaded at the end of the play.

## Policy

- `PermitRootLogin yes`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `PubkeyAuthentication yes`
- SSH port is unchanged

The first matching sshd value wins, so this file is applied before `/etc/ssh/sshd_config.d/*.conf`.

