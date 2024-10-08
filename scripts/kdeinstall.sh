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

# Function to install KDE Plasma based on the distribution
install_kde() {
    case $1 in
        ubuntu|debian|pop)
            sudo apt update
            sudo apt install -y kde-plasma-desktop sddm xorg
            ;;
        fedora)
            sudo dnf groupinstall -y "KDE Plasma Workspaces"
            sudo dnf install -y sddm xorg-x11-server-Xorg
            ;;
        centos|rhel)
            sudo dnf config-manager --set-enabled powertools
            sudo dnf groupinstall -y "KDE Plasma Workspaces"
            sudo dnf install -y sddm xorg-x11-server-Xorg
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm plasma sddm xorg
            ;;
        opensuse|suse)
            sudo zypper install -y -t pattern kde kde_plasma
            sudo zypper install -y sddm xorg-x11-server
            ;;
        *)
            echo "Unsupported distribution. Please install KDE Plasma manually."
            exit 1
            ;;
    esac
}

# Main script
DISTRO=$(detect_distro)
echo "KDE Plasma Installer by TechLogicals"
echo "Detected distribution: $DISTRO"

echo "Installing KDE Plasma..."
install_kde $DISTRO

# Enable SDDM service
sudo systemctl enable sddm

# Ask about autologin
read -p "Do you want to set up autologin? (y/n): " autologin_choice

if [[ $autologin_choice =~ ^[Yy]$ ]]; then
    # Set up autologin
    read -p "Enter the username for autologin: " autologin_user
    sudo mkdir -p /etc/sddm.conf.d
    echo "[Autologin]
User=$autologin_user
Session=plasma" | sudo tee /etc/sddm.conf.d/autologin.conf

    echo "Autologin has been set up for user $autologin_user"
fi

echo "Installation complete. Please reboot your system to start using KDE Plasma."