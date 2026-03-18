#!/bin/bash
set -euo pipefail

SSH_PORT=53122
CONFIG_FILE="/etc/ssh/sshd_config"
HARDENING_TAG="# --- server_setup hardening ---"

# backup (一度だけ)
if [ ! -f "${CONFIG_FILE}.bak.original" ]; then
  cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.original"
fi
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# 既存の sed 置換（デフォルト値のコメント解除対応）
sed -i 's/^#\?Port 22$/Port '"$SSH_PORT"'/' "$CONFIG_FILE"
sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' "$CONFIG_FILE"
sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' "$CONFIG_FILE"
sed -i 's/^#\?PermitRootLogin prohibit-password/PermitRootLogin no/' "$CONFIG_FILE"

# 以前のハードニングブロックがあれば削除して再生成
sed -i "/${HARDENING_TAG}/,\$d" "$CONFIG_FILE"

# 追加ハードニング設定を末尾に追記（sed 漏れがあってもここで確実に上書き）
cat >> "$CONFIG_FILE" <<EOF
${HARDENING_TAG}
Port ${SSH_PORT}

# 認証
PubkeyAuthentication yes
AuthenticationMethods publickey
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM no
PermitRootLogin no
MaxAuthTries 3
LoginGraceTime 30

# 不要な機能を無効化
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no

# バナー情報の抑制
DebianBanner no
EOF

# Ubuntu 24.04+ uses systemd socket activation for sshd.
# sshd_config alone does not control the listen port; the socket unit does.
if systemctl list-unit-files ssh.socket &>/dev/null; then
  echo "Detected systemd socket activation (Ubuntu 24.04+). Overriding ssh.socket..."
  mkdir -p /etc/systemd/system/ssh.socket.d
  cat > /etc/systemd/system/ssh.socket.d/override.conf <<EOF
[Socket]
ListenStream=
ListenStream=0.0.0.0:${SSH_PORT}
ListenStream=[::]:${SSH_PORT}
EOF
  systemctl daemon-reload
fi

# check sshd_config syntax
sshd -t

# restart: try socket-based first, then legacy sshd
if systemctl is-active --quiet ssh.socket 2>/dev/null; then
  systemctl restart ssh.socket
  systemctl restart ssh.service
else
  systemctl restart sshd
fi

echo "SSH hardening complete. Port: $SSH_PORT"
