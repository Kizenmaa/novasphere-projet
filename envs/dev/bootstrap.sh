#!/bin/bash
set -e
apt-get update -y && apt-get install -y nginx awscli
mkdir -p /etc/novasphere
aws ssm get-parameter --region us-east-1 --name /novasphere/dev/db_password \
  --with-decryption --query Parameter.Value --output text > /etc/novasphere/app.conf
chmod 0640 /etc/novasphere/app.conf
echo "<h1>NovaSphere</h1><p>Environnement : dev</p><p>Instance : $(hostname)</p>" > /var/www/html/index.html
systemctl enable --now nginx
