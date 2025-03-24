# Burp-Private-Collaborator-with-PowerDNS-Recursor

This repository contains scripts and configuration files to auto-renew Burp collaborator server SSL certificates without shutting down the collaborator server. The idea is to use a DNS forwarder like PDNS Recursor that intercepts and forwards DNS requests to Burp collaborator DNS server since the configurations in Burp collaborator DNS server are very limited.

---

## Prerequisites

To setup the environment, install the following tools:

- **Burp Pro JAR file**
  - <https://portswigger.net/burp/documentation/desktop/getting-started/download-and-install>
- **PowerDNS Recursor (pdns-recursor)**
  - `sudo apt-get install pdns-recursor`  
- **CertBot**
  - `sudo apt-get install certbot`

---

## Setup Instructions

### 1. **Start Burp Collaborator**
There are many other tutorials online on how to setup Burp private collaborator server but I use the following command:
```bash
java -jar /home/ubuntu/burpcollaborator/burpc.jar --collaborator-server --collaborator-config=/home/ubuntu/burpcollaborator/burpcollaborator.config /tmp
```
Copy the `burpcollaborator.config` from repo and you have to make sure the collaborator is listening on 5353 instead as PDNS recursor should be occupying that port and forwarding all external requests to Burp collaborator on 5353.
Make sure the polling ports 9443 and 9090 and restricted to your VPN and internal IPs only.
Better run Collaborator server as service.

---

## Disable Default pdns-recursor Service

There is one default service `pdns-recursor` setup already but you have to remove it as it does not work due to additional flags. Use these commands to disable it permanently:

```bash
sudo systemctl disable pdns-recursor
sudo systemctl mask pdns-recursor
sudo rm /lib/systemd/system/pdns-recursor.service
sudo systemctl daemon-reload
systemctl status pdns-recursor
```

---

## Create New Recursor Service

Create a new service "recursor" using following commands:

```bash
sudo nano /etc/systemd/system/recursor.service
```

```ini
[Unit]
Description=PowerDNS Recursor
After=network.target

[Service]
ExecStart=/usr/sbin/pdns_recursor
Restart=always
User=root
Group=root
Type=simple
LimitNOFILE=65536
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable recursor
sudo systemctl start recursor
sudo systemctl status recursor
```

---

## Modify PDNS Recursor Config file

Now you need to modify the recursor config file at `/etc/powerdns/recursor.conf` and replace it with the one provided in repo. I have to omit some default flags too to make it work.

You can also run Recursor server with the following command but I recommend adding those flags in config file instead and run it as a service:

```bash
pdns_recursor --local-address=10.x.x.x --forward-zones=.=10.x.x.x:5353 --allow-from=0.0.0.0/0 --lua-dns-script=/etc/powerdns/recursor.lua
```

Make sure to restart service

```bash
sudo systemctl restart recursor
````

---

## Modify LUA Script to Intercept and Change TXT Record for ACME Challenge

Add the LUA file in the repo at the path `/etc/powerdns/recursor.lua` to modify TXT records for only `_acme-challenge`.

---


## Certificate Renewal with Certbot

### 1. **Dry-Run Certificate Renewal**

```bash
certbot renew --dry-run --manual --preferred-challenges dns --manual-auth-hook /home/ubuntu/auth.sh --manual-cleanup-hook /home/ubuntu/cleanup.sh --manual-public-ip-logging-ok
```

Expected Output:

```
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
new certificate deployed without reload, fullchain is
/etc/letsencrypt/live/collab.yourdomain.com/fullchain.pem
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
** DRY RUN: simulating 'certbot renew' close to cert expiry
**          (The test certificates below have not been saved.)

Congratulations, all renewals succeeded. The following certs have been renewed:
  /etc/letsencrypt/live/collab.yourdomain.com/fullchain.pem (success)
** DRY RUN: simulating 'certbot renew' close to cert expiry
**          (The test certificates above have not been saved.)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

---

## Setup Cronjob for Auto-Renewal
If dry-run worked fine, you now need to create cronjob that runs once a day or a week (whatever suits you). Mine runs everyday at 2AM.

```bash
crontab -e
```

```bash
0 2 * * * /usr/bin/certbot renew --manual --preferred-challenges dns --manual-auth-hook /home/ubuntu/auth.sh --manual-cleanup-hook /home/ubuntu/cleanup.sh --manual-public-ip-logging-ok >> /home/ubuntu/burpcollaborator/renew_logs.txt
```

---

## Scripts in the Repo

- `auth.sh` – Handles DNS challenge for Certbot.  
- `cleanup.sh` – Cleans up the DNS records after verification.  

---

## Major Flaw

The DNS requests logged by Burp should be the internal IP of PDNS Recursor.

---
