#!/bin/bash

# UFW (Uncomplicated Firewall) のセットアップ

# ufw がインストールされていなければインストール
if ! command -v ufw &> /dev/null; then
    echo "Installing ufw..."
    sudo apt-get update
    sudo apt-get install -y ufw
fi

# デフォルトポリシー: 受信を拒否、送信を許可
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH ポート 53122/tcp を許可
sudo ufw allow 53122/tcp

# ufw を有効化 (--force で対話プロンプトをスキップ)
sudo ufw --force enable

# ステータスを表示
sudo ufw status verbose
