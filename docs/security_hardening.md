# セキュリティハードニング

Bot 運用 VPS のセキュリティ対策。現状の評価と改善方針をまとめる。

## 現状のセキュリティスタック

| レイヤー | 対策 | 設定 |
|----------|------|------|
| SSH | ポート変更 | 53122 |
| SSH | 公開鍵認証のみ (ed25519) | `AuthenticationMethods publickey` |
| SSH | root ログイン禁止 | `PermitRootLogin no` |
| SSH | 追加ハードニング | `MaxAuthTries 3`, `LoginGraceTime 30`, X11/TCP/AgentForwarding 無効 |
| Firewall | UFW | SSH ポートのみ許可、デフォルト deny incoming |
| Firewall | Docker iptables 無効化 | `daemon.json` で `"iptables": false` |
| IPS | fail2ban | SSH ブルートフォース対策 |
| OS | unattended-upgrades | セキュリティパッチ自動適用 |

## Docker と UFW のバイパス問題

Docker は UFW をバイパスして iptables を直接操作する。つまり `ufw deny` していても Docker が公開したポートはインターネットからアクセス可能になる。

**対策**: `/etc/docker/daemon.json` に `"iptables": false` を設定。`docker-setup.sh` で自動適用される。

**現状のリスク評価**: 本番 Bot の docker-compose.yml は全てポート公開なし（2026-03 時点、19ファイル中ポート公開は tutorial の Jupyter のみ）。実害リスクは低いが、予防的に設定済み。

## ユーザー権限分離

### 方針: deploy と admin-agent の2ユーザー体制

| ユーザー | 用途 | 権限 |
|----------|------|------|
| **deploy** | Bot デプロイ・運用 | docker グループのみ。sudo なし |
| **admin-agent** | ライブラリインストール・システム管理（Claude エージェント用） | sudo NOPASSWD:ALL + docker |

### 経緯

当初 deploy ユーザーに `NOPASSWD:ALL` を付与していたが、日常運用で sudo は不要（CLAUDE.md でも「sudo 禁止」方針）。ライブラリインストール等のシステム管理は頻度が低く、専用ユーザーに分離することで deploy 侵害時の影響を抑える。

### 検討した選択肢（deploy の sudo について）

| 方針 | 内容 | 評価 |
|------|------|------|
| A. 削除 | NOPASSWD をやめてパスワード入力必須に | sudo 自体が不要なら中途半端 |
| B. コマンド限定 | `systemctl restart docker` 等だけ許可 | 洗い出しが必要 |
| C. 現状維持 | 利便性優先 | docker グループ ≒ root なので差は小さい |
| **D. 権限分離** | **deploy から sudo を完全剥奪、admin-agent に移管** | **採用** |

### セットアップ手順

```bash
# 1. admin-agent ユーザーを作成
sudo ./setup/admin-agent-setup.sh deploy

# 2. deploy ユーザーから sudo 権限を剥奪
sudo ./setup/deploy-lockdown.sh deploy

# 3. 検証
su - deploy -c "sudo -l"   # → 「許可されていません」
su - admin-agent -c "sudo whoami"  # → root
```

### docker グループ ≒ root の注意

deploy ユーザーは docker グループに残るため、`docker run -v /:/host ...` でホスト全体にアクセス可能。これは Bot 運用に docker が必須なためのトレードオフ。根本的に解決するには rootless Docker への移行が必要（後述）。

## アカウント侵害の想定シナリオ

NOPASSWD:ALL が問題になるのは deploy ユーザーが侵害されたとき。Bot 運用 VPS で現実的な経路:

### 1. SSH 秘密鍵の漏洩（最も現実的）
- ローカル Mac のマルウェア感染で `~/.ssh/id_ed25519` が窃取される
- バックアップや dotfiles リポジトリへの秘密鍵混入

### 2. サプライチェーン経由
- `pip install` / `npm install` / `curl | sh` で入れたツールに悪意あるコード
- Docker イメージの依存関係に仕込まれたバックドア

### 3. コンテナからのエスケープ
- Docker コンテナ内の脆弱性や設定ミス（`--privileged` 等）でホスト権限取得

### 4. GitHub 経由
- GitHub アカウント侵害 → 悪意あるコード push → VPS で `git pull` + deploy 時に実行

### 侵害時の影響差

| NOPASSWD なし | NOPASSWD:ALL あり |
|---|---|
| deploy ユーザー権限のみ。Docker 操作・ファイル読み書きは可能だが、OS 設定変更やカーネル操作は不可 | `sudo su -` で即 root。SSH 設定変更、バックドア設置、ログ消去、カーネルモジュール挿入など全て可能 |

ただし docker グループがある限り、NOPASSWD の有無に関わらず実質的に root 相当のアクセスが可能。

## Rootless Docker 移行（将来検討）

docker グループ ≒ root 問題の根本解決策。次回サーバー新規セットアップ時に導入を推奨。

### 概要
- Docker デーモンをユーザー空間で実行し、root 権限を一切使わない
- コンテナ侵害 → ホスト root 奪取の経路を遮断

### 移行手順
1. 通常の Docker デーモンを停止
2. `dockerd-rootless-setuptool.sh install` を実行
3. イメージの再 pull / コンテナの再作成

### Bot 運用での注意点

| 項目 | 影響 |
|------|------|
| 特権ポート (< 1024) | bind 不可。Bot は外部 listen しないので問題なし |
| ネットワーク性能 | slirp4netns 経由で若干のレイテンシ増加。API 通信には誤差レベル |
| cgroup v2 必須 | Ubuntu 22.04+ なら対応済み。VPS の OS バージョンを確認 |
| systemd サービス管理 | `systemctl --user` に変わる。自動起動設定の書き直しが必要 |
| 既存コンテナ・ボリューム | 引き継げない。再作成が必要 |
| Taskfile | docker コマンドのソケット指定に微修正が必要な場合あり |

### 推奨タイミング
- 既存 VPS での移行: 全 Bot のダウンタイム + 動作確認が必要で工数中
- **新規サーバーセットアップ時にデフォルトで rootless を採用** するのが最もスムーズ
