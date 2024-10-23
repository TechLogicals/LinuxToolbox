#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

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
    else
        DISTRO=$(uname -s)
    fi
    echo $DISTRO | tr '[:upper:]' '[:lower:]'
}

# Function to detect GPU
detect_gpu() {
    if lspci | grep -i nvidia > /dev/null; then
        echo "nvidia"
    elif lspci | grep -i amd > /dev/null; then
        echo "amd"
    elif lspci | grep -i intel > /dev/null; then
        echo "intel"
    else
        echo "unknown"
    fi
}

# Function to install packages based on the distribution and GPU
install_packages() {
    local distro=$1
    local gpu=$2

    print_color $BLUE "Installing packages for $distro with $gpu GPU..."

    case $distro in
        ubuntu|debian|linuxmint)
            sudo apt-get update
            sudo apt-get install -y steam lutris wine winetricks gamemode mesa-vulkan-drivers vulkan-tools libvulkan1 libvulkan1:i386 libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386
            case $gpu in
                nvidia)
                    sudo apt-get install -y nvidia-driver-470 nvidia-settings
                    ;;
                amd)
                    sudo apt-get install -y mesa-vdpau-drivers
                    ;;
                intel)
                    sudo apt-get install -y intel-media-va-driver
                    ;;
            esac
            ;;
        fedora)
            sudo dnf install -y steam lutris wine winetricks gamemode vulkan-tools mesa-vulkan-drivers.i686 mesa-vulkan-drivers.x86_64 vulkan-loader.i686 vulkan-loader.x86_64 gnutls.i686 freetype.i686 libgcrypt.i686 libgpg-error.i686 libidn.i686 libpng.i686 libX11.i686 mesa-libGL.i686 mesa-libGLU.i686 openal-soft.i686 SDL2.i686 sqlite.i686
            case $gpu in
                nvidia)
                    sudo dnf install -y akmod-nvidia
                    ;;
                amd)
                    sudo dnf install -y mesa-vdpau-drivers
                    ;;
                intel)
                    sudo dnf install -y intel-media-driver
                    ;;
            esac
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm steam lutris wine winetricks gamemode vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools
            case $gpu in
                nvidia)
                    sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils
                    ;;
                amd)
                    sudo pacman -S --noconfirm mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon
                    ;;
                intel)
                    sudo pacman -S --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel
                    ;;
            esac
            ;;
        opensuse*)
            sudo zypper install -y steam lutris wine winetricks gamemode vulkan-tools libvulkan1 libvulkan1-32bit Mesa-vulkan-drivers Mesa-vulkan-drivers-32bit
            case $gpu in
                nvidia)
                    sudo zypper install -y nvidia-driver
                    ;;
                amd)
                    sudo zypper install -y Mesa-dri-nouveau
                    ;;
                intel)
                    sudo zypper install -y intel-media-driver
                    ;;
            esac
            ;;
        *)
            print_color $RED "Unsupported distribution: $distro"
            print_color $YELLOW "Please install the following packages manually: steam lutris wine winetricks gamemode vulkan-tools and appropriate Vulkan drivers for your system"
            exit 1
            ;;
    esac
}

# Main script
print_color $MAGENTA "=== Gaming Dependencies Installation Script by Tech Logicals==="

print_color $CYAN "Detecting Linux distribution..."
DISTRO=$(detect_distro)
print_color $GREEN "Detected distribution: $DISTRO"

print_color $CYAN "Detecting GPU..."
GPU=$(detect_gpu)
print_color $GREEN "Detected GPU: $GPU"

print_color $YELLOW "Installing gaming dependencies..."
install_packages $DISTRO $GPU

print_color $MAGENTA "Installation complete!"
print_color $YELLOW "Note: You may need to restart your system for changes to take effect."
print_color $YELLOW "Some packages might not be available in all repositories. You may need to enable additional repositories or install them manually."




