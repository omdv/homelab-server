# Introduction

Mono repo to manage provision of homelab server. Some features:

- Ubuntu with zfs pool
- Cloud backups
- [K3s cluster](https://github.com/k8s-at-home/template-cluster-k3s)
- Docker-compose apps

## Prepare your local machine

Install following tools:

- age
- ansible
- go-task
- terraform
- direnv
- pre-commit

## Google Cloud Platform

[Service account for Vault auto-unseal](https://shadow-soft.com/vault-auto-unseal/)
OAuth tokens

## Steps

- Fill `.config.env` with your variables. I am keeping most of this as my profile variables, so I am just refering to local env variables.

- Install pre-commit hooks

```bash
task pre-commit:init
```

- Run `./configure.sh --verify` to check dependencies and env vars.

- Baremetal provisioning

```bash
task ansible:playbook:ubuntu-setup
task ansible:playbook:ubuntu-prepare
task ansible:playbook:k3s-install
```

- Cluster preparation

Install zfs-localpv.

```bash
task zfspv
```

On a host system check that dataset under main zfs pool is created:

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
task cluster:vault:init # wait for pod/vault-0 to be up
```

Now the vault should be unsealed and initialized:

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

## Host configuration

Ansible-based provisioning of host system (Ubuntu). Key features:

- zfs and networking
- backup
- system monitoring
- firewall
- email for system notifications
- kubernetes and docker

## Services

Docker-based services:

- plex
- transmission
- calibre
- databases
- jupyter

Kubernetes (k3s) services:

- nginx (static website)
- jupyter
- books (calibre-web)
- summary page for local docker services (custom-built)

also:

- Pod security policies and general hardening
- Traefik ingress with Let's Encrypt
- Forward auth to protect private sites
  ![Services](topology.svg)

## Hardware

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

## Cleaning domain name prior to commit

Commit will be rejected if it detects domain name. Remove it with `make rm_domain`. Add back with `make add_domain`

## TODO

- local docker registry
- docker remote api certs
- ro on /lib/modules
- wireguard and pihole on k3s/traefik
- trusted IPs on ingress
- automatic PV provisioning
- tie zfs pool to k8s
- renovate / automate image tag posting to github
- switch from flux to argo - WIP
- doc/graph generation
- cert-manager
- vault vs age?
- switch from traefik to nginx-ingress with hajimari
- add country live check for wireguard
