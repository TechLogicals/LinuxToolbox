#!/bin/bash

# Function to detect the package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Function to install packages based on the detected package manager
install_packages() {
    local package_manager=$1
    shift
    local packages=("$@")

    case $package_manager in
        apt)
            sudo apt-get update
            sudo apt-get install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -Syu --noconfirm "${packages[@]}"
            ;;
        zypper)
            sudo zypper install -y "${packages[@]}"
            ;;
        *)
            echo "Unsupported package manager. Please install the required packages manually."
            exit 1
            ;;
    esac
}

# Detect the package manager
package_manager=$(detect_package_manager)
echo "Detected package manager: $package_manager"

# Install git if not already installed
install_packages $package_manager git

# Function to download and apply GRUB theme
download_and_apply_theme() {
    local theme_name=$1
    local theme_url=$2
    
    echo "Downloading $theme_name theme..."
    git clone $theme_url
    
    echo "Applying $theme_name theme..."
    cd $(basename $theme_url)
    sudo ./install.sh
    cd ..
    rm -rf $(basename $theme_url)
}

# Download popular GRUB themes
echo "Downloading popular GRUB themes..."
git clone https://github.com/MrVivekRajan/Grub-Themes.git

# Present theme options to user
echo "Available GRUB themes:"
echo "1) Tela"
echo "2) Vimix"
echo "3) Stylish"
echo "4) Slaze"
echo "5) Poly Dark"
echo "6) Poly Light"
echo "7) Fallout"
echo "8) CyberRe"
echo "9) Shodan"
echo "10) Dedsec"
echo "11) Custom theme from Other Grub-Themes"

read -p "Choose a theme to apply (1-11): " theme_choice

case $theme_choice in
    1) download_and_apply_theme "Tela" "https://github.com/vinceliuice/grub2-themes" ;;
    2) download_and_apply_theme "Vimix" "https://github.com/vinceliuice/grub2-themes" ;;
    3) download_and_apply_theme "Stylish" "https://github.com/vinceliuice/grub2-themes" ;;
    4) download_and_apply_theme "Slaze" "https://github.com/vinceliuice/grub2-themes" ;;
    5) download_and_apply_theme "Poly Dark" "https://github.com/shvchk/poly-dark" ;;
    6) download_and_apply_theme "Poly Light" "https://github.com/shvchk/poly-light" ;;
    7) download_and_apply_theme "Fallout" "https://github.com/shvchk/fallout-grub-theme" ;;
    8) download_and_apply_theme "CyberRe" "https://github.com/sarancodes/CyberRe-grub-theme" ;;
    9) download_and_apply_theme "Shodan" "https://github.com/Patato777/Shodan-GRUB-Theme" ;;
    10) download_and_apply_theme "Dedsec" "https://github.com/AdisonCavani/distro-grub-themes" ;;
    11)
        echo "Available themes from MrVivekRajan/Grub-Themes:"
        ls -1 Grub-Themes
        read -p "Enter the name of the theme you want to apply: " custom_theme
        if [ -d "Grub-Themes/$custom_theme" ]; then
            cd Grub-Themes/$custom_theme
            sudo ./install.sh
            cd ../..
        else
            echo "Theme not found."
        fi
        ;;
    *)
        echo "Invalid choice. No theme applied."
        ;;
esac

# Clean up
rm -rf Grub-Themes

echo "GRUB theme installation complete!"

