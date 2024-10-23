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

# Function to install packages based on the distribution
install_packages() {
    case $1 in
        ubuntu|debian|pop)
            sudo apt update
            sudo apt install -y git meson ninja-build pkg-config libglib2.0-dev libcairo2-dev libgdk-pixbuf2.0-dev libxml2-dev libxkbcommon-dev libxkbcommon-x11-dev libwayland-dev libx11-dev libxcb1-dev libxcb-composite0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-res0-dev libsystemd-dev libpulse-dev libupower-glib-dev libpolkit-gobject-1-dev libgnome-desktop-3-dev libgtk-3-dev libgtk-layer-shell-dev libhandy-1-dev libxfixes-dev sddm xorg wayland
            ;;
        fedora|centos|rhel)
            sudo dnf install -y git meson ninja-build pkg-config glib2-devel cairo-devel gdk-pixbuf2-devel libxml2-devel libxkbcommon-devel libxkbcommon-x11-devel wayland-devel libX11-devel libxcb-devel systemd-devel pulseaudio-libs-devel upower-devel polkit-devel gnome-desktop3-devel gtk3-devel gtk-layer-shell-devel libhandy-devel libXfixes-devel sddm xorg-x11-server-Xorg wayland
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm git meson ninja pkg-config glib2 cairo gdk-pixbuf2 libxml2 libxkbcommon libxkbcommon-x11 wayland libx11 libxcb systemd libpulse upower polkit gnome-desktop gtk3 gtk-layer-shell libhandy libxfixes sddm xorg-server wayland
            ;;
        *)
            echo "Unsupported distribution. Please install dependencies manually."
            exit 1
            ;;
    esac
}

# Function to install COSMIC Desktop
install_cosmic() {
    git clone https://github.com/pop-os/cosmic-epoch.git
    cd cosmic-epoch
    meson setup build
    ninja -C build
    sudo ninja -C build install
}

# Function to set up auto-login with SDDM
setup_autologin() {
    read -p "Do you want to set up auto-login? (y/n): " choice
    case "$choice" in 
        y|Y )
            read -p "Enter your username for auto-login: " username
            sudo mkdir -p /etc/sddm.conf.d
            echo "[Autologin]
User=$username
Session=cosmic.desktop" | sudo tee /etc/sddm.conf.d/autologin.conf
            sudo systemctl enable sddm.service
            echo "Auto-login configured for user $username using SDDM"
            ;;
        n|N ) echo "Skipping auto-login setup";;
        * ) echo "Invalid input. Skipping auto-login setup";;
    esac
}

# Main script
echo "COSMIC Desktop Installation Script by Tech Logicals"
echo "==================================================="

# Detect distribution
DISTRO=$(detect_distro)
echo "Detected distribution: $DISTRO"

# Install dependencies
echo "Installing dependencies..."
install_packages $DISTRO

# Install COSMIC Desktop
echo "Installing COSMIC Desktop..."
install_cosmic

# Setup auto-login
setup_autologin

echo "Installation complete. Please reboot your system to start using COSMIC Desktop with SDDM."

