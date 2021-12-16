### VARIABLES ###

GITHUB_REPO='k8s-home-cluster'
TEST_CLUSTER='kind-local'
PROD_CLUSTER='remote'

### FLUX BOOTSTRAP ###

.PHONY: bootstrap_testing
bootstrap_testing:
	kubectl ctx ${TEST_CLUSTER}
	flux bootstrap github \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=./clusters/testing

.PHONY: bootstrap_production
bootstrap_production:
	kubectl ctx ${PROD_CLUSTER}
	flux bootstrap github \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=./clusters/production

.PHONY: bootstrap
bootstrap: bootstrap_testing bootstrap_production


### UTILITIES ###

.PHONY: setup
setup: git_hooks

.PHONY: git_hooks
git_hooks:
	git config core.hooksPath "./git_hooks"

.PHONY: rm_domain
rm_domain:
	fd .yaml --exec sed -i "s/$$HOMELAB_DOMAIN/#HOMELAB_DOMAIN#/g" '{}' \;

.PHONY: add_domain
add_domain:
	fd .yaml --exec sed -i "s/#HOMELAB_DOMAIN#/$$HOMELAB_DOMAIN/g" '{}' \;
