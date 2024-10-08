#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to detect package manager
detect_package_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v apt-get &> /dev/null; then
        echo "apt-get"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    else
        echo "unknown"
    fi
}

# Function to install packages
install_package() {
    local package=$1
    local pm=$(detect_package_manager)
    
    case $pm in
        pacman)
            sudo pacman -S --noconfirm $package
            ;;
        apt-get)
            sudo apt-get update
            sudo apt-get install -y $package
            ;;
        dnf)
            sudo dnf install -y $package
            ;;
        *)
            echo "Unsupported package manager. Please install $package manually."
            ;;
    esac
}

# Function to install AUR helpers (Arch Linux only)
install_aur_helper() {
    local helper=$1
    if [[ $(detect_package_manager) == "pacman" ]]; then
        if ! command -v $helper &> /dev/null; then
            echo "Installing $helper..."
            git clone https://aur.archlinux.org/$helper.git
            cd $helper
            makepkg -si --noconfirm
            cd ..
            rm -rf $helper
        else
            echo "$helper is already installed."
        fi
    else
        echo "$helper is only available for Arch Linux."
    fi
}

# Array of packages
options=("Alacritty" "Rofi" "Neovim" "Kitty" "Steam" "Wine" "Lutris" "Paru" "Yay" "SDDM" "Thorium Browser" "GitHub Desktop" "Quit")
selected=()

# Menu function
menu() {
    echo -e "${YELLOW}Select packages to install (use arrow keys and space to select, enter to confirm):${NC}"
    for i in ${!options[@]}; do
        if [[ ${selected[i]} == true ]]; then
            echo -e "${GREEN}[*] ${options[i]}${NC}"
        elif [[ ${options[i]} == $1 ]]; then
            echo -e "${CYAN}> ${options[i]}${NC}"
        else
            echo -e "  ${options[i]}"
        fi
    done
}

# Initialize selection
select=0

# Capture key presses
while true; do
    # Clear screen and show menu
    clear
    menu "${options[select]}"

    # Capture key press
    read -rsn1 key

    # Handle key press
    case "$key" in
        A) ((select > 0)) && ((select--));;  # Up arrow
        B) ((select < ${#options[@]}-1)) && ((select++));;  # Down arrow
        '') 
            if [[ "${options[select]}" == "Quit" ]]; then
                break
            else
                selected[select]=$([ "${selected[select]}" == true ] && echo false || echo true)
            fi
            ;;
    esac
done

# Install selected packages
for i in ${!options[@]}; do
    if [[ ${selected[i]} == true ]]; then
        case ${options[i]} in
            "Alacritty") install_package alacritty;;
            "Rofi") install_package rofi;;
            "Neovim") install_package neovim;;
            "Kitty") install_package kitty;;
            "Steam") install_package steam;;
            "Wine") install_package wine;;
            "Lutris") install_package lutris;;
            "Paru") install_aur_helper paru;;
            "Yay") install_aur_helper yay;;
            "SDDM") install_package sddm;;
            "Thorium Browser") 
                if [[ $(detect_package_manager) == "pacman" ]]; then
                    install_aur_helper yay
                    yay -S --noconfirm thorium-browser-bin
                else
                    echo "Thorium Browser installation is only supported for Arch Linux via AUR."
                fi
                ;;
            "GitHub Desktop")
                if [[ $(detect_package_manager) == "pacman" ]]; then
                    install_aur_helper yay
                    yay -S --noconfirm github-desktop-bin
                else
                    echo "GitHub Desktop installation is only supported for Arch Linux via AUR."
                fi
                ;;
        esac
    fi
done

echo -e "\e[38;5;196mI\e[38;5;202mn\e[38;5;226ms\e[38;5;082mt\e[38;5;021ma\e[38;5;093ml\e[38;5;196ml\e[38;5;202ma\e[38;5;226mt\e[38;5;082mi\e[38;5;021mo\e[38;5;093mn\e[38;5;196m \e[38;5;202mc\e[38;5;226mo\e[38;5;082mm\e[38;5;021mp\e[38;5;093ml\e[38;5;196me\e[38;5;202mt\e[38;5;226me\e[38;5;082m!\e[38;5;021m \e[38;5;093mb\e[38;5;196my\e[38;5;202m \e[38;5;226mT\e[38;5;082me\e[38;5;021mc\e[38;5;093mh\e[38;5;196m \e[38;5;202mL\e[38;5;226mo\e[38;5;082mg\e[38;5;021mi\e[38;5;093mc\e[38;5;196ma\e[38;5;202ml\e[38;5;226ms\e[0m"

