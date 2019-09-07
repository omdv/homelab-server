Expected environment variables on the host running ansible:
- UBUNTU_CANONICAL_TOKEN
- HOMELAB_ROOT_PASS
- HOMELAB_SMTP_GMAIL_USER
- HOMELAB_SMTP_GMAIL_PASS
- HOMELAB_SMTP_FASTMAIL_USER
- HOMELAB_SMTP_FASTMAIL_PASS
- HOMELAB_NOTIFY_EMAIL
- HOMELAB_BORG_PASSPHRASE
- HOMELAB_SEAFILE_ADMIN
- HOMELAB_SEAFILE_ADMIN_PASS

Execution:
```
ansible-playbook playbook.yml  -i hosts --extra-vars "ansible_sudo_pass="$HOMELAB_ROOT_PASS
```

**TODO**
- watchtower email notifications
- unattended upgrades
- telegraf smartctl
- docker remote api certs
- automate removal of failed zpool devices
- automatically add endpoint to portainer during provisioning

## Manual Steps
1. Configure backup from laptop to homeserver
2. Update No-IP to include sub hosts