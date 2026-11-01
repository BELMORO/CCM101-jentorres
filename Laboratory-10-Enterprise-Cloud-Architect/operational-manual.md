# CCM101 - Cloud Computing
## Enterprise Cloud Architect - Operational Manual

**Project:** Secure Multi-Tier Web Application
**Application Stack:** WordPress + MySQL (Docker Compose)
**Prepared by:** Edwin Belmoro | Lorie Jane Leal | Loreanne Rodelas | Jay Ferrer | Ivan Dela Cruz
**Section:** BSIT 4-H
**Instructor:** Jenkielyn C. Torres
**Date:** November 1, 2026

> DRAFT NOTE (alisin bago i-submit): Ito ay draft na base sa aktwal na deployment ng grupo. Basahin ang bawat bahagi, siguraduhing naiintindihan ninyo, at isulat ulit sa sarili ninyong salita. Ilagay ang sarili ninyong screenshots sa mga bahaging may [SCREENSHOT]. Kung gumamit kayo ng AI sa pagbuo nito, isulat ang disclosure sa dulo ng dokumentong ito.

---

## 1. Overview

Ang proyektong ito ay isang secure, multi-tier, at awtomatikong cloud environment para sa CloudNova Technologies. Tumatakbo ito sa isang Ubuntu Server VM na nasa loob ng VirtualBox. Dalawang container ang bumubuo sa application: ang **WordPress** (web tier) at ang **MySQL** (database tier). May firewall ang server at may awtomatikong backup ng database.

| Item | Detalye |
|---|---|
| Host | Windows laptop |
| Hypervisor | Oracle VirtualBox (Type 2) |
| Guest OS | Ubuntu Server 24.04.5 LTS (headless) |
| VM Resources | 3072 MB RAM, 2 CPU, 25 GB disk |
| Container platform | Docker + Docker Compose v2 |
| Web tier | `wordpress:latest` (container `cloudnova-web`) |
| Database tier | `mysql:8.0` (container `cloudnova-db`) |
| Firewall | UFW, default deny incoming |
| Automation | `automation-script.sh` + cron |

## 2. Architecture

```
+-----------------------------------------------------------+
|  HOST: Windows Laptop (Browser: http://localhost:8080)     |
|                                                            |
|  +------------------------------------------------------+  |
|  |  HYPERVISOR: Oracle VirtualBox (NAT + Port Forward)  |  |
|  |   Host 2222 -> Guest 22   (SSH)                      |  |
|  |   Host 8080 -> Guest 8080 (WordPress)                |  |
|  |                                                      |  |
|  |  +------------------------------------------------+  |  |
|  |  |  VM: Ubuntu Server 24.04 (cloudnova-server)    |  |  |
|  |  |                                                |  |  |
|  |  |  [ UFW Firewall: deny incoming; allow 22, 8080]|  |  |
|  |  |                                                |  |  |
|  |  |  +------------------ Docker ----------------+  |  |  |
|  |  |  | cloudnova-web (WordPress) :8080 -> :80   |  |  |  |
|  |  |  |        |  (internal Docker network)      |  |  |  |
|  |  |  | cloudnova-db  (MySQL 8.0)  :3306 internal|  |  |  |
|  |  |  |  Volumes: wp_data, db_data (persistent)  |  |  |  |
|  |  |  +------------------------------------------+  |  |  |
|  |  |  Cron (daily 18:00 UTC) -> automation-script.sh|  |  |
|  |  +------------------------------------------------+  |  |
|  +------------------------------------------------------+  |
+-----------------------------------------------------------+
```

[SCREENSHOT: architecture-diagram.png]

## 3. Deployment Guide

### 3.1 Gumawa ng VM sa VirtualBox
1. New, pangalan: `CloudNova-Server`, piliin ang Ubuntu Server ISO, i-check ang **Skip Unattended Installation**.
2. Hardware: 3072 MB RAM, 2 CPU, 25 GB disk.
3. Network (Adapter 1: NAT), Port Forwarding:

| Name | Protocol | Host Port | Guest Port |
|---|---|---|---|
| SSH | TCP | 2222 | 22 |
| WordPress | TCP | 8080 | 8080 |

[SCREENSHOT: VM settings at Port Forwarding]

### 3.2 I-install ang Ubuntu Server 24.04.5 LTS
- Sa installer: English, keyboard default, Ubuntu Server, default network, walang proxy, default mirror, entire disk (LVM).
- Profile: server name `cloudnova-server`, username `belmorogroup`.
- I-check ang **Install OpenSSH server**. Huwag mag-select ng snaps.
- Pagkatapos ng install, Reboot Now.

### 3.3 Mag-SSH mula sa laptop

```
ssh belmorogroup@127.0.0.1 -p 2222
```

### 3.4 I-install ang Docker at Docker Compose

```
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo docker --version
sudo docker compose version
```

[SCREENSHOT: bersyon ng Docker at Compose]

### 3.5 Ihanda ang project folder at ang compose file

```
mkdir -p ~/lab10 && cd ~/lab10
```

Ang laman ng `docker-compose.yml` (kopya ng file sa repository):

```yaml
services:
  db:
    image: mysql:8.0
    container_name: cloudnova-db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: RootPass123!
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: WpPass123!
    volumes:
      - db_data:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    container_name: cloudnova-web
    restart: always
    depends_on:
      - db
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: WpPass123!
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/www/html

volumes:
  db_data:
  wp_data:
```

Mga mahalagang bahagi:
- `volumes` (`db_data`, `wp_data`): dito nakasave ang data, kaya hindi ito nawawala kahit i-restart ang VM o container.
- `restart: always`: awtomatikong bumabalik ang mga container pagkatapos ng reboot.
- `depends_on`: nauuna ang database bago ang WordPress.
- Walang `ports` ang database, kaya hindi ito abot mula sa labas ng Docker network.
- Ang mga password sa file ay para sa practice. Sa tunay na client, gumamit ng matibay na password at itago ito sa `.env` file.

### 3.6 Patakbuhin ang stack

```
sudo docker compose up -d
sudo docker ps
```

Buksan sa browser ng laptop: `http://localhost:8080` at tapusin ang WordPress setup. Kung lumabas ang "Error establishing a database connection", maghintay ng 1-2 minuto dahil naghahanda pa ang MySQL, tapos i-refresh.

[SCREENSHOT: docker ps at WordPress site]

## 4. Security Hardening (UFW)

```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 8080/tcp
sudo ufw enable
sudo ufw status verbose
```

Mahalaga: payagan muna ang port 22 bago i-enable ang UFW, para hindi maputol ang SSH.

| Port | Gamit | Estado |
|---|---|---|
| 22/tcp | SSH (remote administration) | Allow |
| 8080/tcp | WordPress web access | Allow |
| Lahat ng iba (kasama ang 3306) | - | Deny |

[SCREENSHOT: sudo ufw status verbose]

## 5. Automation (Backup + Cron)

Ang `automation-script.sh` ay gumagawa ng backup ng WordPress database papunta sa `/home/belmorogroup/backups`, nagbubura ng backup na mas luma sa 7 araw, at nagsusulat sa `backup.log`.

```bash
#!/bin/bash
# CloudNova automated backup: dumps the WordPress database
BACKUP_DIR="/home/belmorogroup/backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
mkdir -p "$BACKUP_DIR"
docker exec -e MYSQL_PWD='RootPass123!' cloudnova-db mysqldump -u root wordpress > "$BACKUP_DIR/wordpress_$DATE.sql"
find "$BACKUP_DIR" -name "wordpress_*.sql" -mtime +7 -delete
echo "[$(date)] Backup done: wordpress_$DATE.sql" >> "$BACKUP_DIR/backup.log"
```

Gawing executable at subukan:

```
chmod +x automation-script.sh
sudo ./automation-script.sh
ls -lh /home/belmorogroup/backups
```

I-schedule gamit ang cron ng root (kailangan ito para magamit ang Docker):

```
(sudo crontab -l 2>/dev/null; echo "0 18 * * * /home/belmorogroup/lab10/automation-script.sh") | sudo crontab -
sudo crontab -l
```

Ang `0 18 * * *` ay tumatakbo araw-araw ng 18:00 UTC, na katumbas ng 2:00 AM oras sa Pilipinas. Gumagamit ng UTC ang server.

[SCREENSHOT: backup file, crontab -l, status ng cron]

## 6. Maintenance at Disaster Recovery

| Gawain | Command |
|---|---|
| Tingnan ang mga container | `sudo docker ps` |
| Tingnan ang logs ng database | `sudo docker logs cloudnova-db --tail 20` |
| I-restart ang WordPress | `sudo docker restart cloudnova-web` |
| Ihinto ang stack | `cd ~/lab10 && sudo docker compose down` |
| Simulan ang stack | `cd ~/lab10 && sudo docker compose up -d` |
| Tingnan ang firewall | `sudo ufw status verbose` |
| Tingnan ang backup log | `cat /home/belmorogroup/backups/backup.log` |
| I-update ang sistema | `sudo apt update && sudo apt upgrade -y` |

Ibalik ang database mula sa backup (palitan ang pangalan ng file):

```
cat /home/belmorogroup/backups/wordpress_YYYY-MM-DD_HH-MM-SS.sql | sudo docker exec -i -e MYSQL_PWD='RootPass123!' cloudnova-db mysql -u root wordpress
```

Ligtas na pag-shutdown ng server:

```
sudo shutdown now
```

## 7. Persistence Test (Reboot)

Nag-reboot at nag-reset ang VM, tapos bumalik ang dalawang container nang kusa at lumabas pa rin ang parehong WordPress site (CloudNova Enterprise, may "Hello world!" post). Ito ang patunay na gumagana ang persistent volumes at `restart: always`.

[SCREENSHOT: docker ps pagkatapos ng reboot at ang WordPress site]

## 8. Troubleshooting

| Problema | Dahilan | Solusyon |
|---|---|---|
| Nag-freeze ang install ng Ubuntu 26.04 (`soft lockup - CPU stuck`) | Bagong kernel na hindi stable sa VirtualBox ng laptop | Gumamit ng Ubuntu Server 24.04 LTS |
| `Error establishing a database connection` | Hindi pa tapos mag-setup ang MySQL | Maghintay 1-2 minuto, o `sudo docker restart cloudnova-web` |
| `ssh: Connection refused` sa port 2222 | Hindi pa tapos mag-boot ang VM o mali ang port forwarding | Hintayin ang login prompt ng VM, i-check ang Port Forwarding |
| Nag-freeze ang VM pagkatapos mag-sleep ang laptop | Na-pause ang VM | Machine > Reset sa VirtualBox. Ligtas ang data sa volumes |
| Hindi gumagana ang `uptime` sa PowerShell | Command ito ng Linux | I-type sa loob ng server pagkatapos mag-SSH |

## 9. Final Checklist ng Requirements

| Requirement | Ebidensya |
|---|---|
| 1. Diagram, VM, networking | architecture-diagram.png, VM at Port Forwarding screenshots |
| 2. Docker, compose, 2 linked containers, persistent volumes | docker-compose.yml, docker ps, reboot test |
| 3. UFW, default deny, port 22 at 8080 lang | ufw status verbose |
| 4. Bash script, executable, cron | automation-script.sh, backup file, crontab -l |
| 5. Documentation | README.md, operational-manual.md, final-reflection.md |

## AI Use Disclosure

[Isulat dito kung gumamit ng AI at para saan. Halimbawa: "Gumamit kami ng AI para sa gabay sa mga hakbang ng deployment at sa pagbuo ng draft ng manual. Kami ang nag-deploy, nag-test, at nag-review ng lahat ng nilalaman."]
