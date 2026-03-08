## ユーザー作成

```
sudo adduser {newuser}
```

ユーザーをsudoグループに追加する場合
```
sudo usermod -aG sudo {username}
```

## 公開鍵でのログインを可能に

```
ssh-copy-id {username}@{hostname or ip}
```

## git
```
cd ~/.ssh
ssh-keygen -t rsa
cat id_rsa.pub
git clone git@github.com:t-nakatani/server_setup.git
```

## sshの設定を上書き
* ポート番号を変更
* パスワード認証を無効化
* 公開鍵認証を有効化

```
chmod +x update_ssh_config.sh
sudo ./update_ssh_config.sh
```

```
Host {host-name}
    HostName {hostname or ip}
    User {username}
    Port {port}
    IdentityFile {path} # ex. ~/.ssh/id_rsa
```

## ファイアウォール
UFW を使って受信をデフォルト拒否し、SSH ポート (53122/tcp) のみ許可する。

```
cd setup
chmod +x ufw-setup.sh
sudo ./ufw-setup.sh
```

`main-setup.sh` を実行する場合は自動で含まれる。

## git
~/.gitconfigを書き換える
```gitconfig
[user]
    name = "My Name"
    email = myname@example.com

```


## 自動セキュリティアップデート

unattended-upgrades を使ってセキュリティアップデートを自動適用する。

```
cd setup
chmod +x unattended-upgrades-setup.sh
sudo ./unattended-upgrades-setup.sh
```

設定確認:
```
systemctl status unattended-upgrades
cat /etc/apt/apt.conf.d/20auto-upgrades
```

## uv のインストール
```
curl -LsSf https://astral.sh/uv/install.sh | sh
```
