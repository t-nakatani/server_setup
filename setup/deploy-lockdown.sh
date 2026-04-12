#!/bin/bash
set -euo pipefail

# deploy ユーザーから不要な権限を剥奪する
# - sudo グループから除外
# - sudoers NOPASSWD 設定を削除
# - docker グループは維持（Bot 運用に必要）
#
# Usage: sudo ./deploy-lockdown.sh [username]
#   username: 対象ユーザー (デフォルト: deploy)
#
# 前提: admin-agent ユーザーが既に作成済みであること
#        (admin-agent-setup.sh を先に実行)

TARGET_USER="${1:-deploy}"

# --- 前提チェック ---
if ! id "admin-agent" &>/dev/null; then
    echo "Error: admin-agent user does not exist." >&2
    echo "Run admin-agent-setup.sh first." >&2
    exit 1
fi

if ! id "${TARGET_USER}" &>/dev/null; then
    echo "Error: user '${TARGET_USER}' does not exist." >&2
    exit 1
fi

echo "Locking down '${TARGET_USER}'..."

# --- sudo グループから除外 ---
if id -nG "${TARGET_USER}" | grep -qw sudo; then
    echo "Removing '${TARGET_USER}' from sudo group..."
    gpasswd -d "${TARGET_USER}" sudo
else
    echo "'${TARGET_USER}' is not in sudo group. Skipping."
fi

# --- sudoers NOPASSWD 設定を削除 ---
SUDOERS_FILE="/etc/sudoers.d/${TARGET_USER}"
if [ -f "${SUDOERS_FILE}" ]; then
    echo "Removing sudoers file: ${SUDOERS_FILE}"
    rm -f "${SUDOERS_FILE}"
else
    echo "No sudoers file found for '${TARGET_USER}'. Skipping."
fi

# --- 残っているグループを確認 ---
echo ""
echo "=== deploy lockdown complete ==="
echo "  User:   ${TARGET_USER}"
echo "  Groups: $(id -nG "${TARGET_USER}")"
echo ""
echo "Verify: try 'sudo -l' as ${TARGET_USER} — should be denied."
