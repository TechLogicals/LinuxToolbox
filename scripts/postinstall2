#!/bin/bash

# by Tech Logicals

set -euo pipefail

DIR="$(dirname "$0")"

#
# Source the functions
#

. "${DIR}"/functions/00-check
. "${DIR}"/functions/01-base
. "${DIR}"/functions/01-misc
. "${DIR}"/functions/02-desktop
. "${DIR}"/functions/03-network
. "${DIR}"/functions/03-packages
. "${DIR}"/functions/04-themes
. "${DIR}"/functions/05-personal

#
# Define main select wrapper
#

function main {
  while true; do
    clear
    show_question "Main Menu - Select an option:"
    echo "1) Base System"
    echo "2) Desktop Environment"
    echo "3) Network & Security"
    echo "4) Applications"
    echo "5) Themes & Personalization"
    echo "6) Miscellaneous"
    echo "7) Autopilot (Install Everything)"
    echo "0) Quit"
    
    read -p "Enter your choice [0-7]: " choice
    
    case $choice in
      0)
        show_success "Thanks for using our util."
        break
        ;;
      1) base_menu ;;
      2) desktop_menu ;;
      3) network_menu ;;
      4) applications_menu ;;
      5) themes_menu ;;
      6) miscellaneous_menu ;;
      7) autopilot ;;
      *) show_warning "Invalid option. Please try again." ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
  done
}

function base_menu {
  while true; do
    clear
    show_question "Base System Menu:"
    echo "1) Install base packages"
    echo "2) Update mirrorlist"
    echo "3) Install firmware"
    echo "4) Enable sudo insults"
    echo "5) Stylize pacman"
    echo "6) Parallelize pacman"
    echo "7) Disable beep"
    echo "0) Return to main menu"
    
    read -p "Enter your choice [0-7]: " choice
    
    case $choice in
      0) break ;;
      1) install_base ;;
      2) update_mirrorlist ;;
      3) install_firmware ;;
      4) enable_sudo_insults ;;
      5) stylize_pacman ;;
      6) parallelize_pacman ;;
      7) disable_beep ;;
      *) show_warning "Invalid option. Please try again." ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
  done
}

function desktop_menu {
  while true; do
    clear
    show_question "Desktop Environment Menu:"
    echo "1) Install KDE"
    echo "2) Install GNOME"
    echo "3) Install Cinnamon"
    echo "4) Install KDE applications"
    echo "5) Install KDE applications (AUR)"
    echo "6) Install Cosmic Desktop"
    echo "7) Install Hyprland"
    echo "8) Install DWM"
    echo "0) Return to main menu"
    
    read -p "Enter your choice [0-5]: " choice
    
    case $choice in
      0) break ;;
      1) install_kde ;;
      2) install_gnome ;;
      3) install_cinnamon ;;
      4) install_apps_kde ;;
      5) install_apps_kde_aur ;;
      6) install_cosmic ;;
      7) install_hyprland ;;
      8) install_dwm ;;
      *) show_warning "Invalid option. Please try again." ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
  done
}

function network_menu {
  while true; do
    clear
    show_question "Network & Security Menu:"
    echo "1) Install network tools"
    echo "2) Install firewall"
    echo "0) Return to main menu"
    
    read -p "Enter your choice [0-2]: " choice
    
    case $choice in
      0) break ;;
      1) install_network ;;
      2) install_firewall ;;
      *) show_warning "Invalid option. Please try again." ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
  done
}

function applications_menu {
  while true; do
    clear
    show_question "Applications Menu:"
    echo "1) Install 3D acceleration"
    echo "2) Install codecs"
    echo "3) Install containers"
    echo "4) Install development tools"
    echo "5) Install development tools (AUR)"
    echo "6) Install extra KDE applications"
    echo "7) Install messaging apps"
    echo "8) Install music apps"
    echo "9) Install LazyVim"
    echo "0) Return to main menu"
    
    read -p "Enter your choice [0-9]: " choice
    
    case $choice in
      0) break ;;
      1) install_3d_accel ;;
      2) install_codecs ;;
      3) install_containers ;;
      4) install_dev ;;
      5) install_dev_aur ;;
      6) install_extra_kde ;;
      7) install_messaging ;;
      8) install_music ;;
      9) install_lazyvim ;;
      *) show_warning "Invalid option. Please try again." ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
  done
}

function themes_menu {
  while true; do
    clear
    show_question "Themes & Personalization Menu:"
    echo "1) Install fonts"
    echo "2) Install Nightfox themes"
    echo "3) Install Powerlevel10k"
    echo "4) Install Plasma timed backgrounds"
    echo "0) Return to main menu"
    
    read -p "Enter your choice [0-4]: " choice
    
    case $choice in
      0) break ;;
      1) install_fonts ;;
      2) install_nightfox_themes ;;
      3) install_powerlevel10k ;;
      4) install_plasma_timed_backgrounds ;;
      *) show_warning "Invalid option. Please try again." ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
  done
}

function miscellaneous_menu {
  while true; do
    clear
    show_question "Miscellaneous Menu:"
    echo "1) Install utils"
    echo "2) Install utils (AUR)"
    echo "3) Install ZSH"
    echo "4) Install TeXLive"
    echo "0) Return to main menu"
    
    read -p "Enter your choice [0-4]: " choice
    
    case $choice in
      0) break ;;
      1) install_utils ;;
      2) install_utils_aur ;;
      3) install_zsh ;;
      4) install_texlive ;;
      *) show_warning "Invalid option. Please try again." ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
  done
}

function autopilot {
  show_question "Running Autopilot..."
  local response
  response=$(ask_question "Let this script install everything? (y/N) (are you mad?)")
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    # Add your autopilot installation logic here
    # For example:
    install_base
    update_mirrorlist
    install_firmware
    install_kde
    # ... add more installation commands as needed
    show_success "Autopilot installation complete."
  else
    show_info "Autopilot cancelled."
  fi
}

#
# Check if dependencies are installed and if network is working
#

check_user
check_network
check_sync_repos
install_post_dependencies

#
#

main