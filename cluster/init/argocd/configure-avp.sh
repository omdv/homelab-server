#!/bin/bash

# This script will create a new AppRole and generate a new secret.
# Result will be stored in the file to be passed to "argocd create new app"
export vv="kubectl exec -n vault vault-0 -- vault"
export VAULT_ROLE_NAME="avp"
export VAULT_ADDR="https://vault.vault.svc.cluster.local"
export PROJECT_DIR=$(git rev-parse --show-toplevel)

if ! $vv token lookup > /dev/null 2>&1; then
    echo "Hey. Please login into VAULT. Stopping...:"
    exit 42
fi
role_id=$($vv read --format=json auth/approle/role/${VAULT_ROLE_NAME}/role-id | jq -r '.data.role_id')
secret_id=$($vv write --format=json -f auth/approle/role/${VAULT_ROLE_NAME}/secret-id | jq -r '.data.secret_id')

export AVP_ROLE_ID=$role_id
export AVP_SECRET_ID=$secret_id

envsubst < "${PROJECT_DIR}/tmpl/cluster/vault-settings.yaml" \
    > "${PROJECT_DIR}/.bootstrap-secrets/avp-secret.yaml"

# jq -n --arg role_id $VAULT_ROLE_ID --arg secret_id $VAULT_SECRET_ID --arg addr $VAULT_ADDR \
# '{VAULT_ADDR: $addr, AVP_AUTH_TYPE: "approle", AVP_ROLE_ID: $role_id, AVP_SECRET_ID: $secret_id, AVP_TYPE: "vault"}' \
# > .cloud-config/vault-approle.json
# kubectl delete secret vault-configuration -n argocd --dry-run=client -o yaml | kubectl apply -f -
# kubectl create secret generic vault-configuration -n argocd --from-env-file (jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" .cloud-config/vault-approle.json | psub)
