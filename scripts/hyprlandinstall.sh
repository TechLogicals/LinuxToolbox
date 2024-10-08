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
            sudo apt install -y meson wget build-essential ninja-build cmake pkg-config git libwayland-dev libx11-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev libsystemd-dev libxcb1-dev libxcb-keysyms1-dev libxcb-icccm4-dev libxcb-randr0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-glx0-dev libpixman-1-dev libdbus-1-dev libgl1-mesa-dev libgbm-dev libdrm-dev libxcb-cursor-dev libxkbcommon-dev libxcb-xkb-dev libxcb-dri3-dev libvulkan-dev libpango1.0-dev libcairo2-dev libgles2-mesa-dev libegl1-mesa-dev libseat-dev libxcb-wm0-dev libxcb-xinerama0-dev libxcb-util-dev libxcb-ewmh-dev libgtk-3-dev libgtk-layer-shell-dev wayland-protocols libwlroots-dev
            ;;
        fedora|centos|rhel)
            sudo dnf install -y meson wget gcc gcc-c++ ninja-build cmake pkgconf-pkg-config git wayland-devel libX11-devel libxcb-devel systemd-devel libdrm-devel mesa-libEGL-devel mesa-libGLES-devel libseat-devel gtk3-devel pango-devel cairo-devel wayland-protocols-devel wlroots-devel
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm meson wget base-devel ninja cmake pkg-config git wayland libx11 libxcb systemd libdrm mesa pango cairo gtk3 seatd wayland-protocols wlroots
            ;;
        opensuse|suse)
            sudo zypper install -y meson wget gcc gcc-c++ ninja cmake pkg-config git wayland-devel libX11-devel libxcb-devel systemd-devel libdrm-devel Mesa-libEGL-devel Mesa-libGLES-devel libseat-devel gtk3-devel pango-devel cairo-devel wayland-protocols-devel wlroots-devel
            ;;
        *)
            echo "Unsupported distribution. Please install dependencies manually."
            exit 1
            ;;
    esac
}

# Function to install Hyprland
install_hyprland() {
    git clone --recursive https://github.com/hyprwm/Hyprland
    cd Hyprland
    meson build
    ninja -C build
    sudo ninja -C build install
    cd ..
    rm -rf Hyprland
}

# Main script
DISTRO=$(detect_distro)
echo "Hyprland Installer by TechLogicals"
echo "Detected distribution: $DISTRO"

echo "Installing dependencies..."
install_packages $DISTRO

echo "Installing Hyprland..."
install_hyprland

# Ask about autologin
read -p "Do you want to set up autologin? (y/n): " autologin_choice

if [[ $autologin_choice =~ ^[Yy]$ ]]; then
    echo "Installing SDDM..."
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

    # Enable SDDM service
    sudo systemctl enable sddm

    # Set up autologin
    read -p "Enter the username for autologin: " autologin_user
    sudo mkdir -p /etc/sddm.conf.d
    echo "[Autologin]
User=$autologin_user
Session=hyprland" | sudo tee /etc/sddm.conf.d/autologin.conf

    echo "Autologin has been set up for user $autologin_user"
fi

echo "Installation complete. You can now start Hyprland by running 'Hyprland' or reboot to use SDDM if you set up autologin."
