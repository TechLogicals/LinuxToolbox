#!/bin/bash

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID" | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        uname -s | tr '[:upper:]' '[:lower:]'
    fi
}

# Function to install gaming dependencies
install_gaming_dependencies() {
    local distro=$1
    case $distro in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y steam lutris wine winetricks vulkan-tools mesa-vulkan-drivers libvulkan1 vulkan-validationlayers
            ;;
        fedora)
            sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
            sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
            sudo dnf install -y steam lutris wine winetricks vulkan-tools mesa-vulkan-drivers vulkan-validation-layers
            ;;
        arch|manjaro)
            sudo pacman -Sy --noconfirm steam lutris wine winetricks vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools
            ;;
        opensuse|suse)
            sudo zypper addrepo https://download.opensuse.org/repositories/games/openSUSE_Leap_15.2/games.repo
            sudo zypper refresh
            sudo zypper install -y steam lutris wine winetricks vulkan-tools libvulkan1 vulkan-validationlayers
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

echo "Installing gaming dependencies..."
install_gaming_dependencies $DISTRO

echo "Verifying installations..."
if command -v steam &> /dev/null && command -v lutris &> /dev/null && command -v wine &> /dev/null; then
    echo "Gaming dependencies have been successfully installed."
else
    echo "Some gaming dependencies may not have been installed correctly."
fi

echo "Installation complete. You may need to restart your system for all changes to take effect."
