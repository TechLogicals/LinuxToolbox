#!/bin/bash

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

# Function to install packages
install_packages() {
    case $1 in
        debian|ubuntu)
            sudo apt-get update
            sudo apt-get install -y git git-lfs
            ;;
        fedora|centos|rhel)
            sudo dnf install -y git git-lfs
            ;;
        arch|manjaro)
            sudo pacman -Sy git git-lfs
            ;;
        opensuse|suse)
            sudo zypper install -y git git-lfs
            ;;
        *)
            echo "Unsupported distribution: $1"
            exit 1
            ;;
    esac
}

# Main script
echo "Detecting Linux distribution..."
DISTRO=$(detect_distro)
echo "Detected distribution: $DISTRO"

echo "Installing Git and Git LFS..."
install_packages $DISTRO

echo "Verifying installation..."
git --version
git lfs --version

echo "Git and Git LFS have been successfully installed."
