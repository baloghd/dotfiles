sudo apt update

# install leftover configuration, if there is any
sudo dpkg --configure -a

# install git, curl
sudo apt install git curl -y 

# install and setup vim 
sudo apt install vim -y

# install and setup zsh
sudo apt install zsh zsh-common -y
chsh -s $(which zsh)
bash -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended

# zsh syntax highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# zsh autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# install zsh plugins
cat ~/.zshrc | sed 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/g' > ~/.zshrc

# install IBM Plex Mono and set it as default monospace font
sudo apt install fonts-ibm-plex -y 

# install autojump
sudo apt install autojump
# add activation to .zshrc
echo ". /usr/share/autojump/autojump.sh" >> .zshrc
