# Introduction

Mono repo to manage provision of homelab server. Some features:

- [host]: Ubuntu with zfs pool
- [host]: Automated external backups
- [host]: [k3s cluster](https://github.com/k8s-at-home/template-cluster-k3s)
- [k3s]: ArgoCD managed apps / gitops
- [k3s]: ZFS-based persistent volumes
- [k3s]: Hashicorp's Vault with external-secrets integration
- [k3s]: Ingress-nginx with cert-manager and hajimari
- [k3s]: Oauth2-proxy email authentication/authorization
- [k3s]: Run apps behind wireguard gateway

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

> :exclamation: You can add an extra level of security and refer to your profile local variables, like I do. This helps with not pushing some values to remote repo by mistake. Git hooks will help with checking it as well.

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
task zfspv
```

(Optional) Check on a host system that dataset under main zfs pool is created:

```bash
zfs list
NAME                       USED  AVAIL     REFER  MOUNTPOINT
pool                      1.79T  3.48T     1.79T  /pool
pool/k3s                   568K  3.48T       96K  /pool/k3s
```

Install and initialize vault.
TODO: describe how to get GCP keys and role

```bash
task cluster:vault:install
task cluster:vault:init
```

Now the vault should be unsealed and initialized, which you can check with:

```bash
k exec -it -n vault vault-0 -- vault

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

Install argocd

```bash
task cluster:argo:install
```

This will install ingress and create an admin password. It will also create two applications: `base` and `apps`. The `base` app will create a load balancer, after which you can access UI at `argo.${your_domain}`. Since this route is protected with oauth2 if you need to connect using CLI open a different tab and forward the port:

```bash
k port-forward -n argocd svc/argocd-server 8080:443
```

Then login into the server with:

```bash
 argocd login localhost:8080 --insecure --username admin --password $HOMELAB_ARGOCD_PASSWORD
 ```

## Hardware

This all runs on single machine in acclaimed Node 304 case, which can house 6 HDDs.
I am considering upgrading to multi-node deployment for "fun" part of it, but the current form-factor meets all needs and is quiet, functional and aesthetic enough to sit in plain sight in the Living room.

[PCPartPicker Part List](https://pcpartpicker.com/list/RBVDTC)

| Type             | Item                                                                                                                                                                                                                 |
| :--------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **CPU**          | [Intel Pentium G4560 3.5 GHz Dual-Core Processor](https://pcpartpicker.com/product/8gKhP6/intel-pentium-g4560-35ghz-dual-core-processor-bx80677g4560)                                                                |
| **CPU Cooler**   | [Noctua NH-L9i 33.84 CFM CPU Cooler](https://pcpartpicker.com/product/xxphP6/noctua-nh-l9i-3384-cfm-cpu-cooler-nh-l9i)                                                                                               |
| **CPU Cooler**   | [Cooler Master Hyper 212 LED 66.3 CFM Rifle Bearing CPU Cooler](https://pcpartpicker.com/product/YdJkcf/cooler-master-hyper-212-led-663-cfm-rifle-bearing-cpu-cooler-rr-212l-16pr-r1)                                |
| **Motherboard**  | [ASRock Z270M-ITX/ac Mini ITX LGA1151 Motherboard](https://pcpartpicker.com/product/2Hbkcf/asrock-z270m-itxac-mini-itx-lga1151-motherboard-z270m-itxac)                                                              |
| **Memory**       | [G.Skill Aegis 16 GB (2 x 8 GB) DDR4-3000 Memory](https://pcpartpicker.com/product/FNprxr/gskill-aegis-16gb-2-x-8gb-ddr4-3000-memory-f43000c16d16gisb)                                                               |
| **Storage**      | [Kingston A1000 240 GB M.2-2280 NVME Solid State Drive](https://pcpartpicker.com/product/FVfhP6/kingston-a1000-240gb-m2-2280-solid-state-drive-sa1000m8240g)                                                         |
| **Storage**      | [Western Digital Red 2 TB 3.5" 5400RPM Internal Hard Drive](https://pcpartpicker.com/product/9wW9TW/western-digital-internal-hard-drive-wd20efrx)                                                                    |
| **Storage**      | [Western Digital Red 2 TB 3.5" 5400RPM Internal Hard Drive](https://pcpartpicker.com/product/9wW9TW/western-digital-internal-hard-drive-wd20efrx)                                                                    |
| **Storage**      | [Western Digital Red 6 TB 3.5" 5400RPM Internal Hard Drive](https://pcpartpicker.com/product/DhsKHx/western-digital-internal-hard-drive-wd60efrx)                                                                    |
| **Storage**      | [Western Digital Red 6 TB 3.5" 5400RPM Internal Hard Drive](https://pcpartpicker.com/product/DhsKHx/western-digital-internal-hard-drive-wd60efrx)                                                                    |
| **Case**         | [Fractal Design Node 304 Mini ITX Tower Case](https://pcpartpicker.com/product/BWFPxr/fractal-design-case-fdcanode304bl)                                                                                             |
| **Power Supply** | [SeaSonic FOCUS Plus Gold 550 W 80+ Gold Certified Fully Modular ATX Power Supply](https://pcpartpicker.com/product/bkp323/seasonic-focus-plus-gold-550w-80-gold-certified-fully-modular-atx-power-supply-ssr-550fx) |
| **Case Fan**     | [Noctua NF-A14 PWM 82.5 CFM 140 mm Fan](https://pcpartpicker.com/product/dwR48d/noctua-case-fan-nfa14pwm)                                                                                                            |

## TODO

- local docker registry
- wireguard and pihole on k3s/traefik
- trusted IPs on ingress
- renovate / automate image tag posting to github
- doc/graph generation
- add country live check for wireguard
- appRole vs root token for external-secrets
- kubeflow??
- argocd [cluster secrets](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters) in vault
- init folder managed by argocd
- automatic liveness probe for VPN
- enable metrics for key components
- valetudo app
- persist secrets
