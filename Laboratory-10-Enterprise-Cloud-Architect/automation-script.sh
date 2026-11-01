#!/bin/bash
# CloudNova automated backup: dumps the WordPress database
BACKUP_DIR="/home/belmorogroup/backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
mkdir -p "$BACKUP_DIR"
docker exec -e MYSQL_PWD='RootPass123!' cloudnova-db mysqldump -u root wordpress > "$BACKUP_DIR/wordpress_$DATE.sql"
find "$BACKUP_DIR" -name "wordpress_*.sql" -mtime +7 -delete
echo "[$(date)] Backup done: wordpress_$DATE.sql" >> "$BACKUP_DIR/backup.log"
