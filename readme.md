Requirements:
some variables (user names, lxd limits, etc) are hard coded.


Execution:
```
ansible-playbook playbook.yml  -i hosts --extra-vars "ansible_sudo_pass="$HOMELAB_ROOT_PASS
```