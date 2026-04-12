#!/bin/bash
set -euo pipefail

# fail2ban のインストール
sudo apt-get update
sudo apt-get install -y fail2ban

# SSH ポートを sshd_config から自動検出（デフォルト: 22）
SSH_PORT=$(grep -E '^Port ' /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
SSH_PORT="${SSH_PORT:-22}"
echo "Detected SSH port: ${SSH_PORT}"

# jail.local の作成
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[sshd]
enabled = true
port = ${SSH_PORT}
maxretry = 3
bantime = 86400
findtime = 3600
banaction = ufw
# Ubuntu 24.04 uses ssh.service instead of sshd.service
journalmatch = _SYSTEMD_UNIT=ssh.service + _COMM=sshd
EOF

# fail2ban の有効化・起動
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# ステータス確認
sudo fail2ban-client status
sudo fail2ban-client status sshd
