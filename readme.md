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
- Pod security policies and general hardening
- Traefik ingress with Let's Encrypt
- Forward auth to protect private sites
- nginx (static website)
- custom-built panel for local docker services

![Services](topology.svg)


## Hardware
[PCPartPicker Part List](https://pcpartpicker.com/list/RBVDTC)

Type|Item|Price
:----|:----|:----
**CPU** | [Intel Pentium G4560 3.5 GHz Dual-Core Processor](https://pcpartpicker.com/product/8gKhP6/intel-pentium-g4560-35ghz-dual-core-processor-bx80677g4560) | Purchased For $68.99 
**CPU Cooler** | [Noctua NH-L9i 33.84 CFM CPU Cooler](https://pcpartpicker.com/product/xxphP6/noctua-nh-l9i-3384-cfm-cpu-cooler-nh-l9i) | $39.95 @ Amazon 
**CPU Cooler** | [Cooler Master Hyper 212 LED 66.3 CFM Rifle Bearing CPU Cooler](https://pcpartpicker.com/product/YdJkcf/cooler-master-hyper-212-led-663-cfm-rifle-bearing-cpu-cooler-rr-212l-16pr-r1) | Purchased For $24.95 
**Motherboard** | [ASRock Z270M-ITX/ac Mini ITX LGA1151 Motherboard](https://pcpartpicker.com/product/2Hbkcf/asrock-z270m-itxac-mini-itx-lga1151-motherboard-z270m-itxac) | Purchased For $109.15 
**Memory** | [G.Skill Aegis 16 GB (2 x 8 GB) DDR4-3000 Memory](https://pcpartpicker.com/product/FNprxr/gskill-aegis-16gb-2-x-8gb-ddr4-3000-memory-f43000c16d16gisb) | Purchased For $104.99 
**Storage** | [Kingston A1000 240 GB M.2-2280 NVME Solid State Drive](https://pcpartpicker.com/product/FVfhP6/kingston-a1000-240gb-m2-2280-solid-state-drive-sa1000m8240g) | $48.96 @ Amazon 
**Storage** | [Western Digital Red 2 TB 3.5" 5400RPM Internal Hard Drive](https://pcpartpicker.com/product/9wW9TW/western-digital-internal-hard-drive-wd20efrx) | Purchased For $86.00 
**Storage** | [Western Digital Red 2 TB 3.5" 5400RPM Internal Hard Drive](https://pcpartpicker.com/product/9wW9TW/western-digital-internal-hard-drive-wd20efrx) | Purchased For $86.00 
**Storage** | [Western Digital Red 6 TB 3.5" 5400RPM Internal Hard Drive](https://pcpartpicker.com/product/DhsKHx/western-digital-internal-hard-drive-wd60efrx) | $350.00 @ Amazon 
**Storage** | [Western Digital Red 6 TB 3.5" 5400RPM Internal Hard Drive](https://pcpartpicker.com/product/DhsKHx/western-digital-internal-hard-drive-wd60efrx) | $350.00 @ Amazon 
**Case** | [Fractal Design Node 304 Mini ITX Tower Case](https://pcpartpicker.com/product/BWFPxr/fractal-design-case-fdcanode304bl) | Purchased For $98.00 
**Power Supply** | [SeaSonic FOCUS Plus Gold 550 W 80+ Gold Certified Fully Modular ATX Power Supply](https://pcpartpicker.com/product/bkp323/seasonic-focus-plus-gold-550w-80-gold-certified-fully-modular-atx-power-supply-ssr-550fx) | Purchased For $80.00 
**Case Fan** | [Noctua NF-A14 PWM 82.5 CFM 140 mm Fan](https://pcpartpicker.com/product/dwR48d/noctua-case-fan-nfa14pwm) | $21.95 @ Amazon 
 | *Prices include shipping, taxes, rebates, and discounts* |
 | **Total** | **$1468.94**

## Execution
```
ansible-playbook playbook.yml  -i hosts --extra-vars "ansible_sudo_pass="$HOMELAB_ROOT_PASS
```

## TODO
- automatic updates of k8s pod images
- microservices (go.micro?) with additional traefik providers
- protect docker.sock for traefik consumption
- local docker registry
- unattended upgrades
- telegraf smartctl
- docker remote api certs
- automate removal of failed zpool devices
- automatically add endpoint to portainer during provisioning

## Manual Steps
1. Configure backup from laptop to homeserver
2. Update No-IP to include sub hosts, done on a local router
3. Prepare environment variables