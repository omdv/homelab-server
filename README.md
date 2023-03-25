# Introduction

Mono repo to manage provision of homelab server.

Provisioning:
- Ubuntu with zfs pool
- Automated external backups
- [k3s cluster](https://github.com/k8s-at-home/template-cluster-k3s)


K3s cluster features and apps:
- ArgoCD gitops
- All secrets in Vault with `external-secrets` integration
- Ingress-nginx with cert-manager and LetsEncrypt
- Ingress behind Oauth2-proxy with email authentication
- Selected apps behind wireguard gateway
- Databases: postgresql, redis, mongodb
- Apache Superset to analyze above databases
- Paperless NGX document archival
- Plex media server and samba
- Sacred Omniboard ML experiment tracking
- Own [Interactive Brokers trading bot](https://github.com/omdv/ibkr-trading)
- Nocodb deployment for above trading app


## Prior to Deployment

### Install following tools on local machine

- age
- ansible
- go-task
- terraform
- direnv
- pre-commit

### Get GCP oauth2 keys and service account

- [Service account for Vault auto-unseal](https://shadow-soft.com/vault-auto-unseal/)
- OAuth tokens (TODO: add link/guide)

## Deployment Guide

- Add your variables to `.config.env`.

> :exclamation: You can add an extra level of security and refer to your profile local variables, or pull secrets from local password-store. Git hooks should prevent you from committing your secrets.

- Install pre-commit hooks

```bash
task pre-commit:init
```

- Add a wireguard config file from your provider into `.bootstrap-secrets` folder and name it `wireguard.conf`.

- Run `./configure.sh --verify` to check dependencies and env vars.

- Baremetal provisioning

```bash
task ansible:playbook:ubuntu-setup
task ansible:playbook:ubuntu-prepare
task ansible:playbook:k3s-install
```

- Cluster bootstrap.

Run `task cluster:install` to bootstrap the cluster. If it fails due to "vault-0 not having assigned host", wait for pod to be up and execute same task again. You can also follow the individual steps below.

Install zfs-localpv:

```bash
task cluster:zfspv
```

(Optional) Check on a host system that dataset under main zfs pool is created:

```bash
zfs list
NAME                       USED  AVAIL     REFER  MOUNTPOINT
pool                      1.79T  3.48T     1.79T  /pool
pool/k3s                   568K  3.48T       96K  /pool/k3s
```

Install and initialize vault [using GCP KMS](https://learn.hashicorp.com/tutorials/vault/autounseal-gcp-kms?in=vault/auto-unseal).
TODO: automate using Terraform

```bash
task cluster:vault:install
task cluster:vault:init
```

Now the vault should be unsealed and initialized, which you can check with:

```bash
k exec -it -n vault vault-0 -- vault status

Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    5
Threshold                3
Version                  1.9.0
Storage Type             file
Cluster Name             vault-cluster-21f860b5
Cluster ID               275d5a0b-5493-8f63-ad90-68bd72c3e02c
HA Enabled               false
```

Inject the secrets into vault:

```bash
./configure.sh --vault
```

You can verify that secrets are injected:

```bash
k exec -n vault vault-0 -- vault kv get kv/secret/oauth2

======= Metadata =======
Key                Value
---                -----
created_time       2021-12-22T20:17:12.538085046Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            7

=============== Data ===============
Key                            Value
---                            -----
VAULT_OAUTH2_CLIENT_ID          *****
VAULT_OAUTH2_CLIENT_SECRET      *****
VAULT_OAUTH2_COOKIE_SECRET      *****
VAULT_OAUTH2_EMAIL_WHITELIST    *****
name                           my-secret
```

> :exclamation: we use oauth2-proxy with [email authentication](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider#email-authentication).
> Comma-separated email whitelist provided via `VAULT_OAUTH2_EMAIL_WHITELIST` can pushed into Vault with `./configure.sh --vault`.

Install external-secrets CRD

```bash
task cluster:secrets:install
```

Install argocd

```bash
task cluster:argo:install
```

ArgoCD will complete the cluster provisioning. After the load balancer is provisioned you should be able to access argocd UI at `argo.${your_domain}`. Alternatively you can connect with CLI with port forwarding, e.g.:

```bash
k port-forward -n argocd svc/argocd-server 8080:443
argocd login localhost:8080 --insecure --username admin --password $HOMELAB_ARGOCD_PASSWORD
 ```

After provisioning ArgoCD will also assume control over its own installation and other applications in `init` folder, which we installed manually in previous steps.

## Cloudflare

Steps above set up the reverse proxy with authentication and certificates. However they expose the server IP. Cloudflare will fix this.

> :exclamation: enable "development" mode in Cloudflare as you add new ingresses to get Let's Encrypt certificate

```bash
./configure.sh --verify
cd provision/terraform/cloudflare
terraform plan
terraform apply
```

## Hardware

This all runs on single machine in acclaimed Node 304 case, which can house 6 HDDs, although I use only 4 at the moment.

I am considering upgrading to multi-node deployment for "fun" part of it, but the current form-factor meets all needs and is quiet, functional and aesthetic enough to sit in plain sight in the Living room.

In Feb 2023 I upgraded old Intel Celeron to i5-11400 CPU. The average load is about 15% now.

[PCPartPicker Part List](https://pcpartpicker.com/list/262PTn)

Type|Item|Price
:----|:----|:----
**CPU** | [Intel Core i5-11400F 2.6 GHz 6-Core Processor](https://pcpartpicker.com/product/qp2WGX/intel-core-i5-11400f-26-ghz-6-core-processor-bx8070811400f) | $129.99 @ Amazon
**CPU Cooler** | [Noctua NH-L9i 33.84 CFM CPU Cooler](https://pcpartpicker.com/product/xxphP6/noctua-nh-l9i-3384-cfm-cpu-cooler-nh-l9i) | $44.95 @ Amazon
**CPU Cooler** | [Cooler Master Hyper 212 LED 66.3 CFM Rifle Bearing CPU Cooler](https://pcpartpicker.com/product/YdJkcf/cooler-master-hyper-212-led-663-cfm-rifle-bearing-cpu-cooler-rr-212l-16pr-r1) | Purchased For $24.95
**Motherboard** | [MSI MPG B560I GAMING EDGE WIFI Mini ITX LGA1200 Motherboard](https://pcpartpicker.com/product/pQ6p99/msi-mpg-b560i-gaming-edge-wifi-mini-itx-lga1200-motherboard-mpg-b560i-gaming-edge-wifi) | $149.99 @ Amazon
**Memory** | [G.Skill Aegis 16 GB (2 x 8 GB) DDR4-3000 CL16 Memory](https://pcpartpicker.com/product/FNprxr/gskill-aegis-16gb-2-x-8gb-ddr4-3000-memory-f43000c16d16gisb) | Purchased For $104.99
**Storage** | [Kingston A1000 240 GB M.2-2280 PCIe 3.0 X4 NVME Solid State Drive](https://pcpartpicker.com/product/FVfhP6/kingston-a1000-240gb-m2-2280-solid-state-drive-sa1000m8240g) |-
**Storage** | [Western Digital Red 2 TB 3.5" 5400 RPM Internal Hard Drive](https://pcpartpicker.com/product/9wW9TW/western-digital-internal-hard-drive-wd20efrx) | Purchased For $86.00
**Storage** | [Western Digital Red 2 TB 3.5" 5400 RPM Internal Hard Drive](https://pcpartpicker.com/product/9wW9TW/western-digital-internal-hard-drive-wd20efrx) | Purchased For $86.00
**Storage** | [Western Digital Red 6 TB 3.5" 5400 RPM Internal Hard Drive](https://pcpartpicker.com/product/DhsKHx/western-digital-internal-hard-drive-wd60efrx) | $154.88 @ Amazon
**Storage** | [Western Digital Red 6 TB 3.5" 5400 RPM Internal Hard Drive](https://pcpartpicker.com/product/DhsKHx/western-digital-internal-hard-drive-wd60efrx) | $154.88 @ Amazon
**Case** | [Fractal Design Node 304 Mini ITX Tower Case](https://pcpartpicker.com/product/BWFPxr/fractal-design-case-fdcanode304bl) | Purchased For $98.00
**Power Supply** | [SeaSonic FOCUS Plus 550 Gold 550 W 80+ Gold Certified Fully Modular ATX Power Supply](https://pcpartpicker.com/product/bkp323/seasonic-focus-plus-gold-550w-80-gold-certified-fully-modular-atx-power-supply-ssr-550fx) | Purchased For $80.00
**Case Fan** | [Noctua A14 PWM 82.5 CFM 140 mm Fan](https://pcpartpicker.com/product/dwR48d/noctua-case-fan-nfa14pwm) | $23.95 @ Amazon

## TODO
- add renovate
- trusted IPs on ingress
- appRole vs root token for external-secrets
- argocd [cluster secrets](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters) in vault

## Apps to try
- identity management for local services - freeIPA?
- local docker registry
- renovate / automate image tag posting to github
- kubeflow
- valetudo private cloud for robo vacuum
- velero
- istio
