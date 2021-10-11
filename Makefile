# MAIN TASKS ##################################################################


# SETUP ######################################################################

.PHONY: setup
setup: git_hooks

.PHONY: git_hooks
git_hooks:
	git config core.hooksPath "./git_hooks"


# UTILITIES ##################################################################

.PHONY: rm_domain
rm_domain:
	fd .yaml --exec sed -i "s/$$HOMELAB_DOMAIN/#HOMELAB_DOMAIN#/g" '{}' \;

.PHONY: add_domain
add_domain:
	fd .yaml --exec sed -i "s/#HOMELAB_DOMAIN#/$$HOMELAB_DOMAIN/g" '{}' \;
