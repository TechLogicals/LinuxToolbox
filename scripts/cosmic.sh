#!/bin/bash
#Cosmic Desktop Installer by TechLogicals

# Function to check if the system is supported
check_system_support() {
    local supported_distros=("pop" "ubuntu" "debian" "arch")
    local distro=$(cat /etc/os-release | grep -w ID | cut -d= -f2 | tr -d '"')
    
    for supported in "${supported_distros[@]}"; do
        if [[ "$distro" == "$supported" ]]; then
            return 0
        fi
    done
    
    echo "Error: Your distribution is not supported by Cosmic Desktop."
    exit 1
}

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    if [[ "$distro" == "arch" ]]; then
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm git base-devel
    else
        sudo apt update
        sudo apt install -y git build-essential meson libgtk-3-dev libglib2.0-dev libcairo2-dev libpango1.0-dev libwayland-dev libxkbcommon-dev
    fi
}

# Function to check if a display manager is already installed
check_dm_installed() {
    if systemctl is-active --quiet gdm.service || \
       systemctl is-active --quiet lightdm.service || \
       systemctl is-active --quiet sddm.service || \
       systemctl is-active --quiet cosmic-greeter.service; then
        return 0
    else
        return 1
    fi
}

# Function to install and configure a display manager
install_display_manager() {
    if check_dm_installed; then
        read -p "A display manager is already installed. Do you want to install a new one? (y/n): " install_new_dm
        if [[ $install_new_dm != [yY] && $install_new_dm != [yY][eE][sS] ]]; then
            echo "Skipping display manager installation."
            return
        fi
    fi

    echo "Choose a display manager:"
    echo "1) LightDM"
    echo "2) SDDM"
    echo "3) Cosmic Greeter"
    read -p "Enter your choice (1-3): " dm_choice

    case $dm_choice in
        1)
            echo "Installing and configuring LightDM..."
            if [[ "$distro" == "arch" ]]; then
                sudo pacman -S --noconfirm lightdm lightdm-gtk-greeter
            else
                sudo apt install -y lightdm
            fi
            sudo systemctl enable lightdm
            ;;
        2)
            echo "Installing and configuring SDDM..."
            if [[ "$distro" == "arch" ]]; then
                sudo pacman -S --noconfirm sddm
            else
                sudo apt install -y sddm
            fi
            sudo systemctl enable sddm
            ;;
        3)
            echo "Installing and configuring Cosmic Greeter..."
            if [[ "$distro" == "arch" ]]; then
                echo "Cosmic Greeter not available for Arch. Using LightDM instead."
                sudo pacman -S --noconfirm lightdm lightdm-gtk-greeter
                sudo systemctl enable lightdm
            else
                sudo apt install -y cosmic-greeter || echo "Cosmic Greeter not available. Using LightDM instead."
                sudo systemctl enable cosmic-greeter || sudo systemctl enable lightdm
            fi
            ;;
        *)
            echo "Invalid choice. Using LightDM as default."
            if [[ "$distro" == "arch" ]]; then
                sudo pacman -S --noconfirm lightdm lightdm-gtk-greeter
            else
                sudo apt install -y lightdm
            fi
            sudo systemctl enable lightdm
            ;;
    esac

    sudo systemctl set-default graphical.target
}

# Function to install Cosmic Desktop
install_cosmic_desktop() {
    echo "Installing Cosmic Desktop..."
    
    if [[ "$distro" == "arch" ]]; then
        # Check if yay is installed
        if ! command -v yay &> /dev/null; then
            echo "yay is not installed. Installing yay..."
            git clone https://aur.archlinux.org/yay.git
            cd yay
            makepkg -si --noconfirm
            cd ..
            rm -rf yay
        fi
        
        echo "Installing Cosmic Desktop using yay..."
        yay -S --noconfirm cosmic
    else
        # Clone the Cosmic Desktop repository
        git clone https://github.com/pop-os/cosmic-desktop.git
        
        # Build and install Cosmic Desktop
        cd cosmic-desktop || exit
        meson build
        ninja -C build
        sudo ninja -C build install
    fi
    
    echo "Cosmic Desktop has been installed successfully!"
}

# Main script execution
echo "Cosmic Desktop Installer by TechLogicals"
echo "========================================"

# Check system support
check_system_support

# Get the distro
distro=$(cat /etc/os-release | grep -w ID | cut -d= -f2 | tr -d '"')

# Prompt user for confirmation
read -p "Do you want to install Cosmic Desktop and its dependencies? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    install_dependencies
    install_display_manager
    install_cosmic_desktop
    
    echo "Installation complete. Please reboot your system to start using Cosmic Desktop."
else
    echo "Installation cancelled."
    exit 0
fi