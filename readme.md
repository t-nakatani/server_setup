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

## git
~/.gitconfigを書き換える
```gitconfig
[user]
    name = "My Name"
    email = myname@example.com

```


## uv のインストール
```
curl -LsSf https://astral.sh/uv/install.sh | sh
```
