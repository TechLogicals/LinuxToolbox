#!/bin/bash
#Desktop Installer by TechLogicals
# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo $DISTRIB_ID
    else
        echo "Unknown"
    fi
}

# Function to install packages based on the package manager
install_packages() {
    local distro=$1
    shift
    case $distro in
        ubuntu|debian|pop)
            sudo apt-get update
            sudo apt-get install -y "$@"
            ;;
        fedora|centos|rhel)
            sudo dnf install -y "$@"
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm "$@"
            ;;
        opensuse*)
            sudo zypper install -y "$@"
            ;;
        *)
            echo "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
}

# Detect the distribution
DISTRO=$(detect_distro)
echo "Detected distribution: $DISTRO"

# Function to install X11/Xorg if needed.  
install_x11() {
    echo "Installing X11/Xorg..."
    case $DISTRO in
        ubuntu|debian|pop)
            install_packages $DISTRO xorg
            ;;
        fedora|centos|rhel)
            install_packages $DISTRO xorg-x11-server-Xorg xorg-x11-xinit
            ;;
        arch|manjaro)
            install_packages $DISTRO xorg-server xorg-xinit
            ;;
        opensuse*)
            install_packages $DISTRO xorg-x11-server
            ;;
        *)
            echo "X11/Xorg installation not supported for this distribution. Please install manually."
            ;;
    esac
}

# Function to install GNOME
install_gnome() {
    echo "Installing GNOME..."
    install_x11
    install_packages $DISTRO gnome gnome-shell
}

# Function to install KDE Plasma
install_kde() {
    echo "Installing KDE Plasma..."
    install_x11
    install_packages $DISTRO kde-plasma-desktop
}

# Function to install Xfce
install_xfce() {
    echo "Installing Xfce..."
    install_x11
    install_packages $DISTRO xfce4 xfce4-goodies
}

# Function to install MATE
install_mate() {
    echo "Installing MATE..."
    install_x11
    install_packages $DISTRO mate-desktop-environment
}

# Function to install Cinnamon
install_cinnamon() {
    echo "Installing Cinnamon..."
    install_x11
    install_packages $DISTRO cinnamon
}

# Function to install LXDE
install_lxde() {
    echo "Installing LXDE..."
    install_x11
    install_packages $DISTRO lxde
}

# Function to install LXQt
install_lxqt() {
    echo "Installing LXQt..."
    install_x11
    install_packages $DISTRO lxqt
}

# Function to install Budgie
install_budgie() {
    echo "Installing Budgie..."
    install_x11
    install_packages $DISTRO budgie-desktop
}

# Function to install Deepin
install_deepin() {
    echo "Installing Deepin..."
    install_x11
    install_packages $DISTRO deepin-desktop-environment
}

# Function to install Hyprland
install_hyprland() {
    echo "Installing Hyprland..."
    # Hyprland is a Wayland compositor, so X11 is not required
    case $DISTRO in
        ubuntu|debian|pop)
            sudo add-apt-repository ppa:hyprwm/hyprland
            sudo apt-get update
            install_packages $DISTRO hyprland
            ;;
        fedora|centos|rhel)
            sudo dnf copr enable solopasha/hyprland
            install_packages $DISTRO hyprland
            ;;
        arch|manjaro)
            install_packages $DISTRO hyprland
            ;;
        *)
            echo "Hyprland installation not supported for this distribution. Please install manually."
            ;;
    esac
}

# Function to install DWM
install_dwm() {
    echo "Installing DWM..."
    install_x11
    install_packages $DISTRO libx11-dev libxft-dev libxinerama-dev
    git clone https://git.suckless.org/dwm
    cd dwm
    sudo make clean install
    cd ..
    rm -rf dwm
}

# Function to install display manager
install_display_manager() {
    echo "Which display manager would you like to install?"
    echo "1) GDM (GNOME Display Manager)"
    echo "2) SDDM (Simple Desktop Display Manager)"
    echo "3) LightDM"
    echo "4) LXDM"
    echo "5) None (use startx or your desktop environment's default)"

    read -p "Enter your choice (1-5): " dm_choice

    case $dm_choice in
        1) install_packages $DISTRO gdm3 ;;
        2) install_packages $DISTRO sddm ;;
        3) install_packages $DISTRO lightdm ;;
        4) install_packages $DISTRO lxdm ;;
        5) echo "Skipping display manager installation." ;;
        *) echo "Invalid choice. Skipping display manager installation." ;;
    esac
}

# Main menu
echo "Which desktop environment would you like to install?"
echo "1) GNOME"
echo "2) KDE Plasma"
echo "3) Xfce"
echo "4) MATE"
echo "5) Cinnamon"
echo "6) LXDE"
echo "7) LXQt"
echo "8) Budgie"
echo "9) Deepin"
echo "10) Hyprland"
echo "11) DWM"

read -p "Enter your choice (1-11): " choice

case $choice in
    1) install_gnome ;;
    2) install_kde ;;
    3) install_xfce ;;
    4) install_mate ;;
    5) install_cinnamon ;;
    6) install_lxde ;;
    7) install_lxqt ;;
    8) install_budgie ;;
    9) install_deepin ;;
    10) install_hyprland ;;
    11) install_dwm ;;
    *) echo "Invalid choice. Exiting." ; exit 1 ;;
esac

# Ask if user wants to install a display manager
read -p "Do you want to install a display manager? (y/n): " install_dm

if [[ $install_dm =~ ^[Yy]$ ]]; then
    install_display_manager
fi

echo "Installation complete. You may need to restart your system and choose your new desktop environment at the login screen."




