#!/bin/bash
#by TechLogicals
# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    else
        DISTRO=$(uname -s)
    fi

    echo $DISTRO | tr '[:upper:]' '[:lower:]'
}

# Function to install Cinnamon desktop and dependencies based on the distribution
install_cinnamon() {
    case $1 in
        ubuntu|pop)
            sudo add-apt-repository universe
            sudo apt update
            sudo apt install -y xorg cinnamon-desktop-environment nemo-fileroller lightdm slick-greeter
            ;;
        debian)
            sudo apt update
            sudo apt install -y xorg cinnamon cinnamon-desktop-environment nemo-fileroller lightdm slick-greeter
            ;;
        fedora)
            sudo dnf install -y @base-x @cinnamon-desktop-environment lightdm slick-greeter
            ;;
        centos|rhel)
            sudo dnf install -y epel-release
            sudo dnf config-manager --set-enabled PowerTools || sudo dnf config-manager --set-enabled powertools
            sudo dnf groupinstall -y "X Window System"
            sudo dnf install -y cinnamon lightdm slick-greeter
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm xorg xorg-server cinnamon nemo-fileroller lightdm lightdm-slick-greeter
            ;;
        opensuse|suse)
            sudo zypper install -y xorg-x11-server cinnamon nemo-fileroller lightdm
            ;;
        *)
            echo "Unsupported distribution. Please install Cinnamon desktop manually."
            exit 1
            ;;
    esac
}

# Main script
DISTRO=$(detect_distro)
echo "Cinnamon Desktop Installer by TechLogicals"
echo "Detected distribution: $DISTRO"

echo "Installing Cinnamon Desktop and dependencies..."
install_cinnamon $DISTRO

# Enable LightDM
sudo systemctl enable lightdm

# Ask about autologin
read -p "Do you want to set up autologin? (y/n): " autologin_choice

if [[ $autologin_choice =~ ^[Yy]$ ]]; then
    # Set up autologin
    read -p "Enter the username for autologin: " autologin_user
    sudo mkdir -p /etc/lightdm
    echo "[Seat:*]
autologin-user=$autologin_user
autologin-session=cinnamon
greeter-session=slick-greeter" | sudo tee -a /etc/lightdm/lightdm.conf

    echo "Autologin has been set up for user $autologin_user"
fi

echo "Installation complete. Please reboot your system to start using Cinnamon Desktop."