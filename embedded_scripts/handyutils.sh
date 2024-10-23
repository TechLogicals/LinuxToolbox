#!/bin/bash

# Function to detect package manager
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Function to install packages
install_package() {
    local package_manager=$1
    local package_name=$2
    
    echo "Installing $package_name..."
    case $package_manager in
        apt)
            sudo apt update && sudo apt install -y $package_name
            ;;
        dnf|yum)
            sudo $package_manager install -y $package_name
            ;;
        pacman)
            sudo pacman -Syu --noconfirm $package_name
            ;;
        zypper)
            sudo zypper install -y $package_name
            ;;
        *)
            echo "Unsupported package manager. Please install $package_name manually."
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo "$package_name installed successfully!"
    else
        echo "Failed to install $package_name. Please try again or install manually."
    fi
}

# Detect package manager
PM=$(detect_package_manager)

# Define installation functions for each utility
install_htop() { install_package $PM htop; }
install_neofetch() { install_package $PM neofetch; }
install_tldr() {
    if [ "$PM" = "pacman" ]; then
        install_package $PM tldr
    else
        install_package $PM python3-pip
        pip3 install --user tldr
    fi
}
install_vim() { install_package $PM vim; }
install_tmux() { install_package $PM tmux; }
install_git() { install_package $PM git; }
install_curl() { install_package $PM curl; }
install_wget() { install_package $PM wget; }
install_tree() { install_package $PM tree; }
install_nmap() { install_package $PM nmap; }
install_iotop() { install_package $PM iotop; }
install_ncdu() { install_package $PM ncdu; }
install_rsync() { install_package $PM rsync; }
install_unzip() { install_package $PM unzip; }
install_zip() { install_package $PM zip; }
install_jq() { install_package $PM jq; }
install_fzf() { install_package $PM fzf; }
install_ripgrep() { install_package $PM ripgrep; }
install_fd() { install_package $PM fd-find; }
install_bat() { install_package $PM bat; }
install_exa() { install_package $PM exa; }
install_mtr() { install_package $PM mtr; }
install_iftop() { install_package $PM iftop; }
install_nethogs() { install_package $PM nethogs; }
install_glances() { install_package $PM glances; }
install_duf() { install_package $PM duf; }
install_nnn() { install_package $PM nnn; }
install_ranger() { install_package $PM ranger; }
install_mc() { install_package $PM mc; }
install_zsh() { install_package $PM zsh; }
install_fish() { install_package $PM fish; }
install_screen() { install_package $PM screen; }
install_byobu() { install_package $PM byobu; }
install_mosh() { install_package $PM mosh; }
install_autojump() { install_package $PM autojump; }
install_thefuck() { install_package $PM thefuck; }
install_httpie() { install_package $PM httpie; }
install_ncat() { install_package $PM ncat; }
install_socat() { install_package $PM socat; }
install_iperf() { install_package $PM iperf; }
install_stress() { install_package $PM stress; }
install_strace() { install_package $PM strace; }
install_ltrace() { install_package $PM ltrace; }
install_lsof() { install_package $PM lsof; }
install_tcpdump() { install_package $PM tcpdump; }
install_wireshark() { install_package $PM wireshark; }
install_netcat() { install_package $PM netcat; }
install_traceroute() { install_package $PM traceroute; }
install_whois() { install_package $PM whois; }
install_dnsutils() { install_package $PM dnsutils; }
install_ipcalc() { install_package $PM ipcalc; }

# Array of all utilities with descriptions
declare -A utilities
utilities=(
    ["htop"]="Interactive process viewer"
    ["neofetch"]="System information tool"
    ["tldr"]="Simplified man pages"
    ["vim"]="Improved vi text editor"
    ["tmux"]="Terminal multiplexer"
    ["git"]="Version control system"
    ["curl"]="Command-line tool for transferring data"
    ["wget"]="Non-interactive network downloader"
    ["tree"]="Directory listing in tree-like format"
    ["nmap"]="Network exploration tool and security scanner"
    ["iotop"]="I/O monitoring tool"
    ["ncdu"]="NCurses Disk Usage"
    ["rsync"]="Fast, versatile file copying tool"
    ["unzip"]="List, test and extract compressed files in a ZIP archive"
    ["zip"]="Package and compress (archive) files"
    ["jq"]="Command-line JSON processor"
    ["fzf"]="Command-line fuzzy finder"
    ["ripgrep"]="Recursively searches directories for a regex pattern"
    ["fd"]="Simple, fast and user-friendly alternative to find"
    ["bat"]="Cat clone with syntax highlighting and Git integration"
    ["exa"]="Modern replacement for ls"
    ["mtr"]="Network diagnostic tool"
    ["iftop"]="Display bandwidth usage on an interface"
    ["nethogs"]="Net top tool grouping bandwidth per process"
    ["glances"]="Cross-platform system monitoring tool"
    ["duf"]="Disk Usage/Free Utility"
    ["nnn"]="The missing terminal file manager for X"
    ["ranger"]="Console file manager with VI key bindings"
    ["mc"]="Midnight Commander, a visual file manager"
    ["zsh"]="Z shell, an extended Bourne shell"
    ["fish"]="Friendly interactive shell"
    ["screen"]="Screen manager with VT100/ANSI terminal emulation"
    ["byobu"]="Text-based window manager and terminal multiplexer"
    ["mosh"]="Mobile shell, remote terminal application"
    ["autojump"]="Faster way to navigate your filesystem"
    ["thefuck"]="Magnificent app which corrects your previous console command"
    ["httpie"]="User-friendly cURL replacement"
    ["ncat"]="Concatenate and redirect sockets"
    ["socat"]="Multipurpose relay for bidirectional data transfer"
    ["iperf"]="Network bandwidth measurement tool"
    ["stress"]="Tool to impose load on and stress test systems"
    ["strace"]="Diagnostic, debugging and instructional userspace utility"
    ["ltrace"]="Library call tracer"
    ["lsof"]="List open files"
    ["tcpdump"]="Dump traffic on a network"
    ["wireshark"]="Network protocol analyzer"
    ["netcat"]="TCP/IP swiss army knife"
    ["traceroute"]="Print the route packets trace to network host"
    ["whois"]="Client for the whois directory service"
    ["dnsutils"]="DNS utilities"
    ["ipcalc"]="IP address calculator"
)

# Function to display menu
display_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo "=== $title ==="
    for i in "${!options[@]}"; do
        printf "%3d) %s\n" $((i+1)) "${options[i]}"
    done
    echo
}

# Function to get user selection
get_selection() {
    local prompt="$1"
    local max="$2"
    local selection
    
    while true; do
        read -p "$prompt" selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$max" ]; then
            return "$selection"
        fi
        echo "Invalid selection. Please try again."
    done
}

# Main menu
while true; do
    clear
    echo "Linux Utility Installer"
    echo "======================="
    echo "Detected package manager: $PM"
    echo
    
    options=("Install a utility" "View installed utilities" "Exit")
    display_menu "Main Menu" "${options[@]}"
    get_selection "Enter your choice: " "${#options[@]}"
    choice=$?
    
    case $choice in
        1)
            while true; do
                clear
                echo "Available Utilities:"
                echo "===================="
                utility_names=(${!utilities[@]})
                display_menu "Utilities" "${utility_names[@]}"
                echo "$((${#utility_names[@]}+1))) Back to main menu"
                
                get_selection "Select a utility to install (or $((${#utility_names[@]}+1)) to go back): " "$((${#utility_names[@]}+1))"
                selection=$?
                
                if [ "$selection" -eq "$((${#utility_names[@]}+1))" ]; then
                    break
                else
                    utility=${utility_names[$((selection-1))]}
                    description=${utilities[$utility]}
                    echo
                    echo "You selected: $utility"
                    echo "Description: $description"
                    read -p "Do you want to install this utility? (y/n): " confirm
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        install_$utility
                    fi
                    read -p "Press Enter to continue..."
                fi
            done
            ;;
        2)
            clear
            echo "Installed Utilities:"
            echo "===================="
            for util in "${!utilities[@]}"; do
                if command -v $util &> /dev/null; then
                    echo "✓ $util - ${utilities[$util]}"
                fi
            done
            read -p "Press Enter to continue..."
            ;;
        3)
            echo "Thank you for using the Linux Utility Installer by Tech Logicals. Goodbye!"
            exit 0
            ;;
    esac
done


