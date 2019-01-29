Requirements:
some variables (user names, lxd limits, etc) are hard coded.

**TODO**
- unattended upgrades
- telegraf smartctl
- schedule bi-monthly scrubs
- docker remote api certs
- automate removal of failed zpool devices

Execution:
```
ansible-playbook playbook.yml  -i hosts --extra-vars "ansible_sudo_pass="$HOMELAB_ROOT_PASS
```

