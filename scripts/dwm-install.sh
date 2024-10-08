#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to detect the package manager
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo -e "${RED}Unknown package manager. Please install manually.${NC}"
        exit 1
    fi
}

# Function to install packages based on the detected package manager
install_packages() {
    local pm=$1
    shift
    case $pm in
        apt)
            sudo apt update
            sudo apt install -y "$@"
            ;;
        dnf)
            sudo dnf install -y "$@"
            ;;
        pacman)
            sudo pacman -Syu --noconfirm "$@"
            ;;
    esac
}

# Detect package manager
PM=$(detect_package_manager)
echo -e "${CYAN}Detected package manager: $PM${NC}"

# Install X11, SDDM, and other utilities
echo -e "${YELLOW}Installing X11, SDDM, and other utilities...${NC}"
case $PM in
    apt)
        install_packages $PM xorg sddm dmenu st xterm firefox git build-essential libx11-dev libxft-dev libxinerama-dev alacritty
        ;;
    dnf)
        install_packages $PM xorg-x11-server-Xorg sddm dmenu st xterm firefox git gcc libX11-devel libXft-devel libXinerama-devel alacritty
        ;;
    pacman)
        install_packages $PM xorg sddm dmenu st xterm firefox git base-devel libx11 libxft libxinerama alacritty
        ;;
esac

# Build and install dwm
echo -e "${MAGENTA}Building and installing dwm...${NC}"
git clone https://git.suckless.org/dwm
cd dwm
sudo make clean install
cd ..
rm -rf dwm

# Install Thorium browser
echo -e "${BLUE}Installing Thorium browser...${NC}"
wget https://github.com/Alex313031/thorium/releases/download/M117.0.5938.157/thorium-browser_117.0.5938.157_amd64.deb
sudo dpkg -i thorium-browser_117.0.5938.157_amd64.deb
sudo apt install -f
rm thorium-browser_117.0.5938.157_amd64.deb

# Enable SDDM service
sudo systemctl enable sddm

# Create a .desktop file for DWM
echo -e "${GREEN}Creating .desktop file for DWM...${NC}"
echo "[Desktop Entry]
Name=dwm
Comment=Dynamic window manager
Exec=dwm
Type=Application" | sudo tee /usr/share/xsessions/dwm.desktop > /dev/null

# Ask user if they want to set up auto-login
read -p "$(echo -e ${YELLOW}"Do you want to set up auto-login? (y/n): "${NC})" AUTO_LOGIN

if [ "$AUTO_LOGIN" = "y" ]; then
    read -p "$(echo -e ${YELLOW}"Enter the username for auto-login: "${NC})" USERNAME
    
    # Set up auto-login in SDDM
    sudo mkdir -p /etc/sddm.conf.d
    echo "[Autologin]
User=$USERNAME
Session=dwm" | sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null

    echo -e "${GREEN}Auto-login has been set up for user $USERNAME${NC}"
fi

echo -e "${CYAN}Installation complete. Please reboot your system to start using DWM.${NC}"
echo -e "${BLUE}Thanks for using this script by Tech Logicals!!${NC}"



