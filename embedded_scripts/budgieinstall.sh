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

# Function to install Budgie desktop based on the distribution
install_budgie() {
    case $1 in
        ubuntu|pop)
            sudo add-apt-repository -y ppa:ubuntubudgie/backports
            sudo apt update
            sudo apt install -y ubuntu-budgie-desktop xorg
            ;;
        debian)
            sudo apt update
            sudo apt install -y budgie-desktop xorg
            ;;
        fedora)
            sudo dnf groupinstall -y "Budgie Desktop"
            sudo dnf install -y xorg-x11-server-Xorg
            ;;
        centos|rhel)
            sudo dnf copr enable -y frankcrawford/budgie-desktop
            sudo dnf install -y budgie-desktop xorg-x11-server-Xorg
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm budgie-desktop xorg
            ;;
        opensuse|suse)
            sudo zypper addrepo https://download.opensuse.org/repositories/X11:Budgie/openSUSE_Tumbleweed/X11:Budgie.repo
            sudo zypper refresh
            sudo zypper install -y budgie-desktop xorg-x11-server
            ;;
        *)
            echo "Unsupported distribution. Please install Budgie desktop manually."
            exit 1
            ;;
    esac
}

# Main script
DISTRO=$(detect_distro)
echo "Budgie Desktop Installer by TechLogicals"
echo "Detected distribution: $DISTRO"

echo "Installing Budgie Desktop..."
install_budgie $DISTRO

# Install and enable SDDM
case $DISTRO in
    ubuntu|debian|pop)
        sudo apt install -y sddm
        ;;
    fedora|centos|rhel)
        sudo dnf install -y sddm
        ;;
    arch|manjaro)
        sudo pacman -S --noconfirm sddm
        ;;
    opensuse|suse)
        sudo zypper install -y sddm
        ;;
esac

sudo systemctl enable sddm

# Ask about autologin
read -p "Do you want to set up autologin? (y/n): " autologin_choice

if [[ $autologin_choice =~ ^[Yy]$ ]]; then
    # Set up autologin
    read -p "Enter the username for autologin: " autologin_user
    sudo mkdir -p /etc/sddm.conf.d
    echo "[Autologin]
User=$autologin_user
Session=budgie-desktop" | sudo tee /etc/sddm.conf.d/autologin.conf

    echo "Autologin has been set up for user $autologin_user"
fi

echo "Installation complete. Please reboot your system to start using Budgie Desktop."