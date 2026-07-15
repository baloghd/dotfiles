#!/bin/bash
# Install zsh + oh-my-zsh + plugins + autojump + kafeitu theme.

set -euo pipefail

. "$(dirname "$0")/../lib/detect-distro.sh"

$PKG_INSTALL zsh

# oh-my-zsh installer (idempotent: refuses to reinstall if ~/.oh-my-zsh exists)
yes | RUNZSH=no CHSH=no bash -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# -- Plugins (skip if already cloned) ---------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

grep -q "zsh-syntax-highlighting" "$HOME/.zshrc" \
  || sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/g' "$HOME/.zshrc"

# -- autojump (activation file path differs by distro) ----------------------
$PKG_INSTALL autojump
case "$DISTRO" in
  fedora)        AUTOJUMP_INIT="/usr/share/autojump/autojump.zsh" ;;
  ubuntu|debian) AUTOJUMP_INIT="/usr/share/autojump/autojump.sh" ;;
esac
grep -q "autojump" "$HOME/.zshrc" || echo ". $AUTOJUMP_INIT" >> "$HOME/.zshrc"

# -- Default shell + theme --------------------------------------------------
chsh -s "$(which zsh)"
sed -i "s/ZSH_THEME=.*/ZSH_THEME=\"kafeitu\"/g" "$HOME/.zshrc"