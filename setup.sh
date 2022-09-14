sudo apt update

# install leftover configuration, if there is any
sudo dpkg --configure -a

# install git, curl
sudo apt install git curl -y 

# install and setup vim 
sudo apt install vim -y

# install and setup zsh
sudo apt install zsh zsh-common zsh-autosuggestions zsh-syntax-highlighting -y
bash -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended

# install IBM Plex Mono and set it as default monospace font
sudo apt install fonts-ibm-plex -y 

# install autojump
sudo apt install autojump
# add activation to .zshrc
echo ". /usr/share/autojump/autojump.sh" >> .zshrc
