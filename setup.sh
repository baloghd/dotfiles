sudo apt update

# install leftover configuration, if there is any
sudo dpkg --configure -a

# install and setup zsh
sudo apt install zsh zsh-common zsh-autosuggestions zsh-syntax-highlighting -y

# install IBM Plex Mono
sudo apt install fonts-ibm-plex -y 

# install vim, git, curl
sudo apt install vim git curl -y 

# install autojump