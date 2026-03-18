#!/bin/bash
set -euo pipefail

# Docker のインストール (Compose V2 同梱)
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
./get-docker.sh
rm -f get-docker.sh

# Docker が UFW をバイパスして iptables を直接操作するのを防ぐ
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "iptables": false
}
EOF

# ユーザーを docker グループに追加
sudo usermod -aG docker "${SUDO_USER:-$USER}"

# Docker 再起動して daemon.json を反映
sudo systemctl restart docker

# バージョン確認
docker --version
docker compose version
