#!/bin/bash
set -euo pipefail

# admin-agent ユーザーの作成
# - sudo NOPASSWD:ALL 権限を付与
# - deploy ユーザーの SSH 公開鍵をコピー（同じ鍵でログイン可能）
# - docker グループに追加（メンテナンス用）
#
# Usage: sudo ./admin-agent-setup.sh [deploy_username]
#   deploy_username: SSH 鍵のコピー元ユーザー (デフォルト: deploy)

ADMIN_USER="admin-agent"
DEPLOY_USER="${1:-deploy}"

# --- ユーザー作成 ---
if id "${ADMIN_USER}" &>/dev/null; then
    echo "User '${ADMIN_USER}' already exists. Skipping creation."
else
    echo "Creating user '${ADMIN_USER}'..."
    adduser --disabled-password --gecos "Admin Agent" "${ADMIN_USER}"
fi

# --- sudo グループ追加 ---
echo "Adding '${ADMIN_USER}' to sudo group..."
usermod -aG sudo "${ADMIN_USER}"

# --- sudo NOPASSWD 設定 ---
echo "Configuring sudo NOPASSWD for '${ADMIN_USER}'..."
SUDOERS_FILE="/etc/sudoers.d/${ADMIN_USER}"
echo "${ADMIN_USER} ALL=(ALL) NOPASSWD:ALL" > "${SUDOERS_FILE}"
chmod 0440 "${SUDOERS_FILE}"

if visudo -c -f "${SUDOERS_FILE}"; then
    echo "sudoers validated."
else
    echo "Error: sudoers validation failed." >&2
    rm -f "${SUDOERS_FILE}"
    exit 1
fi

# --- docker グループ追加 ---
if getent group docker &>/dev/null; then
    echo "Adding '${ADMIN_USER}' to docker group..."
    usermod -aG docker "${ADMIN_USER}"
fi

# --- SSH 公開鍵をコピー ---
DEPLOY_HOME=$(eval echo "~${DEPLOY_USER}")
ADMIN_HOME=$(eval echo "~${ADMIN_USER}")
DEPLOY_KEYS="${DEPLOY_HOME}/.ssh/authorized_keys"

if [ -f "${DEPLOY_KEYS}" ]; then
    echo "Copying SSH authorized_keys from '${DEPLOY_USER}'..."
    mkdir -p "${ADMIN_HOME}/.ssh"
    cp "${DEPLOY_KEYS}" "${ADMIN_HOME}/.ssh/authorized_keys"
    chown -R "${ADMIN_USER}:${ADMIN_USER}" "${ADMIN_HOME}/.ssh"
    chmod 700 "${ADMIN_HOME}/.ssh"
    chmod 600 "${ADMIN_HOME}/.ssh/authorized_keys"
else
    echo "Warning: ${DEPLOY_KEYS} not found. Set up SSH keys manually." >&2
fi

# --- シェル設定 ---
echo "Setting default shell to bash for '${ADMIN_USER}'..."
chsh -s /bin/bash "${ADMIN_USER}"

echo ""
echo "=== admin-agent setup complete ==="
echo "  User:   ${ADMIN_USER}"
echo "  Groups: sudo, docker"
echo "  Sudo:   NOPASSWD:ALL"
echo "  SSH:    copied from ${DEPLOY_USER}"
echo ""
echo "Test login: ssh -p 53122 ${ADMIN_USER}@<host>"
