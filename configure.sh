#!/usr/bin/env bash

set -o errexit
set -o pipefail

# shellcheck disable=SC2155
export PROJECT_DIR=$(git rev-parse --show-toplevel)
# export WIREGUARD_DIR="${PROJECT_DIR}/.wireguard"
# export WIREGUARD_CONFIG_FILE=$(base64 -w 0 ${WIREGUARD_DIR}/$(ls ${WIREGUARD_DIR}))

# shellcheck disable=SC2155
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# shellcheck disable=SC1091
source "${PROJECT_DIR}/.config.env"

show_help() {
cat << EOF
Usage: $(basename "$0") <options>
    -h, --help                      Display help
    --verify                        Verify .config.env settings
    --vault                         Inject env vars into vault
EOF
}

main() {
    local verify=
    local vault=

    parse_command_line "$@"
    verify_binaries

    if [[ "${verify}" == 1 ]]; then
        verify_ansible_hosts
        verify_age
        verify_git_repository
        verify_cloudflare
        verify_vault
        verify_argo
        success
    elif [[ "${vault}" == 1 ]]; then
        generate_cluster_secrets
    else
        # sops configuration file
        envsubst < "${PROJECT_DIR}/tmpl/.sops.yaml" \
            > "${PROJECT_DIR}/.sops.yaml"
# cluster
# envsubst < "${PROJECT_DIR}/tmpl/cluster/cluster-settings.yaml" \
#     > "${PROJECT_DIR}/cluster/base/cluster-settings.yaml"
# envsubst < "${PROJECT_DIR}/tmpl/argo/values.yaml" \
#     > "${PROJECT_DIR}/argo/base/values.yaml"

# # wireguard
# # export WIREGUARD_CONFIG_FILE=$(cat ${PROJECT_DIR}/.wireguard/$(ls ${PROJECT_DIR}/.wireguard/) | base64) &&\
# envsubst < "${PROJECT_DIR}/tmpl/cluster/wireguard.secrets.sops.yaml" \
#     > "${PROJECT_DIR}/cluster/base/wireguard.secrets.sops.yaml"
# sops --encrypt --in-place "${PROJECT_DIR}/cluster/base/wireguard.secrets.sops.yaml"

        # template argo values
        export ARGO_PWD=$(htpasswd -nbBC 10 "" $BOOTSTRAP_ARGO_ADMIN_PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/' | base64 -w 0)
        envsubst < "${PROJECT_DIR}/tmpl/argo/secret.yaml" \
            > "${PROJECT_DIR}/cluster/init/argocd/secret.yaml"

# # terraform
# envsubst < "${PROJECT_DIR}/tmpl/terraform/secret.sops.yaml" \
#     > "${PROJECT_DIR}/provision/terraform/cloudflare/secret.sops.yaml"
# sops --encrypt --in-place "${PROJECT_DIR}/provision/terraform/cloudflare/secret.sops.yaml"

        # ansible
        generate_ansible_hosts
        generate_ansible_host_secrets
    fi
}

parse_command_line() {
    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            --verify)
                verify=1
                ;;
            --vault)
                vault=1
                ;;
            *)
                break
                ;;
        esac

        shift
    done

    if [[ -z "$verify" ]]; then
        verify=0
    fi
    if [[ -z "$vault" ]]; then
        vault=0
    fi
}

_has_binary() {
    command -v "${1}" >/dev/null 2>&1 || {
        _log "ERROR" "${1} is not installed or not found in \$PATH"
        exit 1
    }
}

_has_envar() {
    local option="${1}"
    # shellcheck disable=SC2015
    [[ "${!option}" == "" ]] && {
        _log "ERROR" "Unset variable ${option}"
        exit 1
    } || {
        _log "INFO" "Found variable '${option}' with value '${!option}'"
    }
}

_has_valid_ip() {
    local ip="${1}"
    local variable_name="${2}"

    if ! ipcalc "${ip}" | awk 'BEGIN{FS=":"; is_invalid=0} /^INVALID/ {is_invalid=1; print $1} END{exit is_invalid}' >/dev/null 2>&1; then
        _log "INFO" "Variable '${variable_name}' has an invalid IP address '${ip}'"
        exit 1
    else
        _log "INFO" "Variable '${variable_name}' has a valid IP address '${ip}'"
    fi
}

verify_age() {
    _has_envar "BOOTSTRAP_AGE_PUBLIC_KEY"
    _has_envar "SOPS_AGE_KEY_FILE"

    if [[ ! "$BOOTSTRAP_AGE_PUBLIC_KEY" =~ ^age.* ]]; then
        _log "ERROR" "BOOTSTRAP_AGE_PUBLIC_KEY does not start with age"
        exit 1
    else
        _log "INFO" "Age public key is in the correct format"
    fi

    if [[ ! -f ~/.config/sops/age/keys.txt ]]; then
        _log "ERROR" "Unable to find Age file keys.txt in ~/.config/sops/age"
        exit 1
    else
        _log "INFO" "Found Age public key '${BOOTSTRAP_AGE_PUBLIC_KEY}'"
    fi
}

verify_binaries() {
    _has_binary "ansible"
    _has_binary "envsubst"
    _has_binary "flux"
    _has_binary "git"
    _has_binary "age"
    _has_binary "helm"
    _has_binary "ipcalc"
    _has_binary "jq"
    _has_binary "sops"
    _has_binary "ssh"
    _has_binary "task"
    _has_binary "terraform"
}

verify_git_repository() {
    _has_envar "BOOTSTRAP_GIT_REPOSITORY"

    export GIT_TERMINAL_PROMPT=0
    pushd "$(mktemp -d)" >/dev/null 2>&1
    [ "$(git ls-remote "${BOOTSTRAP_GIT_REPOSITORY}" 2> /dev/null)" ] || {
        _log "ERROR" "Unable to find the remote Git repository '${BOOTSTRAP_GIT_REPOSITORY}'"
        exit 1
    }
    popd >/dev/null 2>&1
    export GIT_TERMINAL_PROMPT=1
}

verify_cloudflare() {
    local account_zone=
    local errors=

    _has_envar "BOOTSTRAP_CLOUDFLARE_APIKEY"
    _has_envar "BOOTSTRAP_CLOUDFLARE_DOMAIN"
    _has_envar "BOOTSTRAP_CLOUDFLARE_EMAIL"

    # Try to retrieve zone information from Cloudflare's API
    account_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${BOOTSTRAP_CLOUDFLARE_DOMAIN}&status=active" \
        -H "X-Auth-Email: ${BOOTSTRAP_CLOUDFLARE_EMAIL}" \
        -H "X-Auth-Key: ${BOOTSTRAP_CLOUDFLARE_APIKEY}" \
        -H "Content-Type: application/json"
    )

    if [[ "$(echo "${account_zone}" | jq ".success")" == "true" ]]; then
        _log "INFO" "Verified Cloudflare Account and Zone information"
    else
        errors=$(echo "${account_zone}" | jq -c ".errors")
        _log "ERROR" "Unable to get Cloudflare Account and Zone information ${errors}"
        exit 1
    fi
}

verify_ansible_hosts() {
    local node_id=
    local node_addr=
    local node_username=
    local node_password=
    local node_control=

    for var in "${!BOOTSTRAP_ANSIBLE_HOST_ADDR_@}"; do
        node_id=$(echo "${var}" | awk -F"_" '{print $5}')
        node_addr="BOOTSTRAP_ANSIBLE_HOST_ADDR_${node_id}"
        node_username="BOOTSTRAP_ANSIBLE_SSH_USERNAME_${node_id}"
        node_password="BOOTSTRAP_ANSIBLE_SUDO_PASSWORD_${node_id}"
        node_control="BOOTSTRAP_ANSIBLE_CONTROL_NODE_${node_id}"

        _has_envar "${node_addr}"
        _has_envar "${node_username}"
        _has_envar "${node_password}"
        _has_envar "${node_control}"

        if ssh -q -o BatchMode=yes -o ConnectTimeout=5 "${!node_username}"@"${!var}" "true"; then
            _log "INFO" "Successfully SSH'ed into host '${!var}' with username '${!node_username}'"
        else
            _log "ERROR" "Unable to SSH into host '${!var}' with username '${!node_username}'"
            exit 1
        fi
    done
}

verify_vault() {
    _has_envar "VAULT_OAUTH2_CLIENT_ID"
    _has_envar "VAULT_OAUTH2_CLIENT_SECRET"
    _has_envar "VAULT_OAUTH2_COOKIE_SECRET"
    _has_envar "VAULT_OAUTH2_EMAIL_WHITELIST"
    _log "INFO" "Found variables for OAUTH2"
}

generate_cluster_secrets() {
    # initialize secret @ secret/oauth2
    kubectl exec -n vault vault-0 -- vault kv put kv/secret/oauth2 name=my-secret
    for var in "${!VAULT_OAUTH2@}"; do
        kubectl exec -n vault vault-0 -- vault kv patch kv/secret/oauth2 "$var"="$(echo -n ${!var})"
    done

    # patch email whitelist
    kubectl exec -n vault vault-0 -- vault kv patch kv/secret/oauth2 \
        VAULT_OAUTH2_EMAIL_WHITELIST="$(echo "${VAULT_OAUTH2_EMAIL_WHITELIST}" | sed 's/,/\n/g')"
}

verify_argo() {
    _has_envar "BOOTSTRAP_ARGO_ADMIN_PASSWORD"
    _log "INFO" "Found variables for ARGO"
}

success() {
    printf "\nAll checks pass!"
    exit 0
}

generate_ansible_host_secrets() {
    local node_id=
    local node_username=
    local node_password=
    {
        node_username="BOOTSTRAP_ANSIBLE_SSH_USERNAME"
        node_password="BOOTSTRAP_ANSIBLE_SUDO_PASSWORD"
        printf "kind: Secret\n"
        printf "ansible_user: %s\n" "${!node_username}"
        printf "ansible_become_pass: %s\n" "${!node_password}"
    } > "${PROJECT_DIR}/provision/ansible/inventory/host_vars/${BOOTSTRAP_ANSIBLE_HOST_NAME}.sops.yml"
    sops --encrypt --in-place "${PROJECT_DIR}/provision/ansible/inventory/host_vars/${BOOTSTRAP_ANSIBLE_HOST_NAME}.sops.yml"
}

generate_ansible_hosts() {
    {
        printf -- "---\n"
        printf "kubernetes:\n"
        printf "  children:\n"
        printf "    master:\n"
        printf "      hosts:\n"
        printf "        %s:\n" "${BOOTSTRAP_ANSIBLE_HOST_NAME}"
        printf "          ansible_host: %s\n" "${BOOTSTRAP_ANSIBLE_HOST_ADDR}"
    } > "${PROJECT_DIR}/provision/ansible/inventory/hosts.yml"
}

_log() {
    local type="${1}"
    local msg="${2}"
    printf "[%s] [%s] %s\n" "$(date -u)" "${type}" "${msg}"
}

main "$@"
