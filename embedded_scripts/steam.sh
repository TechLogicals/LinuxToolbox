#!/bin/bash

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID" | tr '[:upper:]' '[:lower:]'
    elif type lsb_release >/dev/null 2>&1; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        uname -s | tr '[:upper:]' '[:lower:]'
    fi
}

# Function to install Steam
install_steam() {
    local distro=$1
    case $distro in
        ubuntu|debian)
            sudo add-apt-repository multiverse
            sudo apt update
            sudo apt install -y steam
            ;;
        fedora)
            sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
            sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
            sudo dnf install -y steam
            ;;
        arch|manjaro)
            sudo pacman -Sy steam
            ;;
        opensuse|suse)
            sudo zypper addrepo https://download.opensuse.org/repositories/games/openSUSE_Leap_15.2/games.repo
            sudo zypper refresh
            sudo zypper install -y steam
            ;;
        *)
            echo "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
}

# Main script
echo "Detecting Linux distribution..."
DISTRO=$(detect_distro)
echo "Detected distribution: $DISTRO"

echo "Installing Steam..."
install_steam $DISTRO

echo "Verifying installation..."
if command -v steam &> /dev/null; then
    echo "Steam has been successfully installed."
else
    echo "Steam installation failed or not found in PATH."
fi
