#!/bin/bash

# Zsh のインストール
sudo apt-get install -y zsh
chsh -s $(which zsh)

# Zsh 用 Git 統合スクリプトのダウンロード
cd ~/.zsh
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
curl -o git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o _git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh

# Peco のインストール
sudo apt install -y peco
git clone https://github.com/jimeh/zsh-peco-history.git ~/.zsh/zsh-peco-history
source ~/.zsh/zsh-peco-history/zsh-peco-history.zsh
