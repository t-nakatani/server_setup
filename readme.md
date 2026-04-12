# サーバーセットアップ

## 手順概要

1. ユーザー作成・SSH 鍵登録 (手動)
2. sudo NOPASSWD 設定 (手動) ← **SSH ハードニング前に必須**
3. SSH ハードニング (手動)
4. メインセットアップ (自動: `main-setup.sh`)
5. 個別設定 (手動: git config, GitHub SSH 鍵)
6. 権限分離 (admin-agent / deploy lockdown)

---

## 1. ユーザー作成

```
sudo adduser {newuser}
sudo usermod -aG sudo {username}
```

### 公開鍵でのログインを可能に

ローカルマシンから実行:
```
ssh-copy-id {username}@{hostname or ip}
```

## 2. sudo NOPASSWD 設定

**重要**: SSH ハードニング (Step 3) で root ログインが無効化されるため、先に deploy ユーザーへ sudo NOPASSWD を付与する。これを忘れると管理操作が不能になり、VNC コンソールからの復旧が必要になる。

```
sudo ./setup/sudo-nopasswd-setup.sh deploy
```

## 3. SSH ハードニング

ポート番号変更・パスワード認証無効化・root ログイン無効化を行う。

サーバー上でこのリポジトリを clone:
```
cd ~/.ssh
ssh-keygen -t ed25519 -C "$(hostname)-github"
cat id_ed25519.pub
# → GitHub に登録
git clone git@github.com:t-nakatani/server_setup.git
```

SSH 設定を上書き:
```
chmod +x update_ssh_config.sh
sudo ./update_ssh_config.sh
```

ローカルの `~/.ssh/config` に追加:
```
Host {host-name}
    HostName {hostname or ip}
    User {username}
    Port 53122
    IdentityFile ~/.ssh/id_ed25519
```

## 4. メインセットアップ

以下を一括で実行する:

| ステップ | 内容 |
|----------|------|
| base-setup | apt update/upgrade, 基本パッケージ (git, vim, curl, wget, unzip), タイムゾーン (Asia/Tokyo) |
| docker-setup | Docker, Docker Compose |
| zsh-setup | Zsh, peco, git-prompt |
| ufw-setup | UFW ファイアウォール (SSH ポートのみ許可) |
| fail2ban-setup | fail2ban (SSH ブルートフォース対策: 3回失敗で24h BAN, UFW 連携) |
| unattended-upgrades-setup | セキュリティアップデート自動適用 |
| uv-setup | uv (Python パッケージマネージャ) |

```
cd setup
chmod +x main-setup.sh
sudo ./main-setup.sh
```

### 個別実行

各スクリプトは単独でも実行可能:
```
cd setup
sudo ./base-setup.sh
sudo ./docker-setup.sh
# ...
```

### ステータス確認

```
# UFW
sudo ufw status verbose

# fail2ban
sudo fail2ban-client status sshd

# unattended-upgrades
systemctl is-enabled unattended-upgrades
cat /etc/apt/apt.conf.d/20auto-upgrades

# Docker
docker --version && docker compose version

# uv
uv --version
```

## 5. 個別設定 (手動)

### git config

```
git config --global user.name "My Name"
git config --global user.email "myname@example.com"
```

### GitHub SSH 鍵

```
ssh-keygen -t ed25519 -C "{host-name}"
cat ~/.ssh/id_ed25519.pub
# → GitHub Settings → SSH and GPG keys に登録

ssh-keyscan github.com >> ~/.ssh/known_hosts
ssh -T git@github.com
```

## 6. ユーザー権限分離

Bot 運用 (deploy) とシステム管理 (admin-agent) を分離する。
Step 4 のメインセットアップ完了後に実行する。

```bash
# 1. admin-agent ユーザーを作成（sudo NOPASSWD:ALL + deploy の SSH 鍵をコピー）
sudo ./setup/admin-agent-setup.sh deploy

# 2. deploy ユーザーから sudo 権限を剥奪
sudo ./setup/deploy-lockdown.sh deploy
```

| ユーザー | 用途 | 権限 |
|----------|------|------|
| deploy | Bot デプロイ・運用 | docker グループのみ |
| admin-agent | ライブラリインストール・システム管理 | sudo NOPASSWD:ALL + docker |

ローカルの `~/.ssh/config` に追加:
```
Host {host-name}-admin
    HostName {hostname or ip}
    User admin-agent
    Port 53122
    IdentityFile ~/.ssh/id_ed25519
```

> **Note**: `sudo-nopasswd-setup.sh` は汎用スクリプトとして残してあるが、
> 通常は上記の権限分離手順を使うこと。

## ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [docs/security_hardening.md](docs/security_hardening.md) | セキュリティ対策の全体像・方針・将来検討事項 |
