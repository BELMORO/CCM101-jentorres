# Laboratory 10: Enterprise Cloud Architect

**Course:** CCM101 - Cloud Computing
**Project:** Secure Multi-Tier Web Application (WordPress + MySQL)
**Prepared by:** Edwin Belmoro | Lorie Jane Leal | Loreanne Rodelas | Jay Ferrer | Ivan Dela Cruz
**Section:** BSIT 4-H

## Buod

Isang secure, multi-tier, at awtomatikong private cloud environment na tumatakbo sa Ubuntu Server VM (VirtualBox). Ang application ay WordPress (web tier) at MySQL (database tier) na pinapatakbo gamit ang Docker Compose, may persistent volumes, may UFW firewall, at may awtomatikong backup gamit ang Bash script at cron.

## Mga File sa Folder na Ito

| File | Laman |
|---|---|
| `README.md` | Buod ng proyekto |
| `architecture-diagram.png` | Network topology at architecture diagram |
| `docker-compose.yml` | Infrastructure as Code ng WordPress + MySQL |
| `automation-script.sh` | Backup script ng database (naka-schedule sa cron) |
| `operational-manual.md` | Handover manual: deploy, secure, maintain |
| `final-reflection.md` | Reflection mula Mission 1 hanggang Mission 10 |

## Mabilis na Deploy

```
mkdir -p ~/lab10 && cd ~/lab10
# ilagay ang docker-compose.yml at automation-script.sh sa folder na ito
sudo docker compose up -d
chmod +x automation-script.sh
```

Buksan ang `http://localhost:8080` (o ang port 8080 ng server) para sa WordPress.

## Mga Requirement

- [x] Requirement 1: Architecture diagram, VM, at networking
- [x] Requirement 2: Docker Compose, 2 linked containers, persistent volumes
- [x] Requirement 3: UFW, default deny, port 22 at 8080 lang ang bukas
- [x] Requirement 4: Executable Bash script at cron job
- [ ] Requirement 5: Operational manual at final reflection (kumpletuhin ng grupo)

Para sa buong detalye, basahin ang [operational-manual.md](operational-manual.md).
