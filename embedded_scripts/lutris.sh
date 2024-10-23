#!/bin/bash

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID | tr '[:upper:]' '[:lower:]'
    elif type lsb_release >/dev/null 2>&1; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo $DISTRIB_ID | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        uname -s | tr '[:upper:]' '[:lower:]'
    fi
}

# Function to install Lutris and dependencies
install_lutris() {
    local distro=$1
    case $distro in
        ubuntu|debian)
            sudo add-apt-repository ppa:lutris-team/lutris
            sudo apt update
            sudo apt install -y lutris
            sudo apt install -y wine
            ;;
        fedora)
            sudo dnf install -y lutris
            sudo dnf install -y wine
            ;;
        arch|manjaro)
            sudo pacman -Sy lutris
            sudo pacman -Sy wine
            ;;
        opensuse|suse)
            sudo zypper addrepo https://download.opensuse.org/repositories/games/openSUSE_Leap_15.2/games.repo
            sudo zypper refresh
            sudo zypper install -y lutris
            sudo zypper install -y wine
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

echo "Installing Lutris and dependencies..."
install_lutris $DISTRO

echo "Verifying installation..."
lutris --version

echo "Lutris has been successfully installed."
