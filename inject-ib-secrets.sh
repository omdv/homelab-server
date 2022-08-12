#!/usr/bin/env bash

main() {
    inject_ib_secrets
}

inject_ib_secrets() {
    # initialize secret @ secret/ibkr
    kubectl exec -n vault vault-0 -- vault kv put kv/secret/ibkr name=my-ibkr-secret
    kubectl exec -n vault vault-0 -- vault kv patch kv/secret/ibkr "VAULT_IBKR_USER_ID"="$TWS_USER_ID"
    kubectl exec -n vault vault-0 -- vault kv patch kv/secret/ibkr "VAULT_IBKR_PASSWORD"="$TWS_PASSWORD"
}

main
