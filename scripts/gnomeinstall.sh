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

# Function to install GNOME desktop with Wayland and dependencies based on the distribution
install_gnome_wayland() {
    case $1 in
        ubuntu|pop)
            sudo apt update
            sudo apt install -y ubuntu-gnome-desktop gnome-tweaks gnome-shell-extensions wayland-protocols libwayland-client0 libwayland-cursor0 libwayland-server0
            ;;
        debian)
            sudo apt update
            sudo apt install -y gnome gnome-shell gnome-tweaks gnome-shell-extensions wayland-protocols libwayland-client0 libwayland-cursor0 libwayland-server0
            ;;
        fedora)
            sudo dnf groupinstall -y "GNOME Desktop Environment"
            sudo dnf install -y gnome-tweaks gnome-shell-extensions wayland-protocols
            ;;
        centos|rhel)
            sudo dnf groupinstall -y "Server with GUI" "GNOME Desktop" "Fonts"
            sudo dnf install -y gnome-tweaks gnome-shell-extensions wayland-protocols
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm gnome gnome-extra gnome-tweaks wayland
            ;;
        opensuse|suse)
            sudo zypper install -y -t pattern gnome gnome_basis
            sudo zypper install -y gnome-tweaks gnome-shell-extensions wayland
            ;;
        *)
            echo "Unsupported distribution. Please install GNOME desktop manually."
            exit 1
            ;;
    esac
}

# Main script
DISTRO=$(detect_distro)
echo "GNOME Desktop (Wayland) Installer by TechLogicals"
echo "Detected distribution: $DISTRO"

echo "Installing GNOME Desktop with Wayland and dependencies..."
install_gnome_wayland $DISTRO

# Install and enable GDM (GNOME Display Manager)
case $DISTRO in
    ubuntu|debian|pop)
        sudo apt install -y gdm3
        ;;
    fedora|centos|rhel)
        sudo dnf install -y gdm
        ;;
    arch|manjaro)
        sudo pacman -S --noconfirm gdm
        ;;
    opensuse|suse)
        sudo zypper install -y gdm
        ;;
esac

sudo systemctl enable gdm

# Configure GDM to use Wayland by default
sudo sed -i 's/#WaylandEnable=false/WaylandEnable=true/' /etc/gdm3/custom.conf

# Ask about autologin
read -p "Do you want to set up autologin? (y/n): " autologin_choice

if [[ $autologin_choice =~ ^[Yy]$ ]]; then
    # Set up autologin
    read -p "Enter the username for autologin: " autologin_user
    sudo mkdir -p /etc/gdm3
    echo "[daemon]
AutomaticLoginEnable=True
AutomaticLogin=$autologin_user
WaylandEnable=true" | sudo tee -a /etc/gdm3/custom.conf

    echo "Autologin has been set up for user $autologin_user with Wayland enabled"
fi

echo "Installation complete. Please reboot your system to start using GNOME Desktop with Wayland."