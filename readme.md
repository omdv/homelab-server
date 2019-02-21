Expected environment variables on the host running ansible:
- UBUNTU_CANONICAL_TOKEN
- HOMELAB_ROOT_PASS
- HOMELAB_SMTP_GMAIL_USER
- HOMELAB_SMTP_GMAIL_PASS
- HOMELAB_SMTP_FASTMAIL_USER
- HOMELAB_SMTP_FASTMAIL_PASS
- HOMELAB_NOTIFY_EMAIL
- HOMELAB_BORG_PASSPHRASE

Execution:
```
ansible-playbook playbook.yml  -i hosts --extra-vars "ansible_sudo_pass="$HOMELAB_ROOT_PASS
```

**TODO**
- unattended upgrades
- telegraf smartctl
- schedule bi-monthly scrubs
- docker remote api certs
- automate removal of failed zpool devices

## Manual Steps
1. Configure backup from laptop to homeserver