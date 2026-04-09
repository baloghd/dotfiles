#!/bin/bash

sudo dnf install zsh -y

yes | bash -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

grep -q "zsh-syntax-highlighting" ~/.zshrc || sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/g' ~/.zshrc

sudo dnf install autojump
grep -q "autojump.zsh" ~/.zshrc || echo ". /usr/share/autojump/autojump.zsh" >> ~/.zshrc

chsh -s $(which zsh)

sed -i "s/ZSH_THEME=.*/ZSH_THEME=\"kafeitu\"/g" ~/.zshrc
