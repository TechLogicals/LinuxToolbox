#!/bin/bash
# Script to install Starship, Zoxide, Fastfetch, and configure a nice bash prompt on any Linux distribution
# by Tech Logicals

# Function to install Starship
install_starship() {
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

# Function to install Zoxide
install_zoxide() {
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

# Function to install Fastfetch on Debian-based distros
install_fastfetch_debian() {
    sudo apt update
    sudo apt install -y fastfetch
}

# Function to install Fastfetch on Red Hat-based distros
install_fastfetch_redhat() {
    sudo dnf install -y fastfetch
}

# Function to install Fastfetch on Arch-based distros
install_fastfetch_arch() {
    sudo pacman -Syu --needed fastfetch
}

# Function to install fonts
install_fonts() {
    # Install Fira Code
    git clone --depth=1 https://github.com/tonsky/FiraCode.git /tmp/FiraCode
    sudo mkdir -p /usr/share/fonts/truetype/firacode
    sudo cp /tmp/FiraCode/distr/ttf/*.ttf /usr/share/fonts/truetype/firacode/
    
    # Install Meslo Fonts
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /tmp/powerlevel10k
    sudo mkdir -p /usr/share/fonts/truetype/meslo
    sudo cp /tmp/powerlevel10k/Meslo/*.ttf /usr/share/fonts/truetype/meslo/
    
    # Clean up
    rm -rf /tmp/FiraCode /tmp/powerlevel10k
    
    # Update font cache
    sudo fc-cache -fv
}

# Detect the Linux distribution and call the appropriate function
if [ -f /etc/debian_version ]; then
    install_starship
    install_zoxide
    install_fastfetch_debian
elif [ -f /etc/redhat-release ]; then
    install_starship
    install_zoxide
    install_fastfetch_redhat
elif [ -f /etc/arch-release ]; then
    install_starship
    install_zoxide
    install_fastfetch_arch
else
    echo "Unsupported Linux distribution"
    exit 1
fi

# Install fonts
install_fonts

# Ensure Zoxide is in the PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Define bash prompts
prompt1='PS1="\[\e[1;32m\]\u@\h \[\e[1;34m\]\w\[\e[0m\] $(starship prompt) \$ "'
prompt2='PS1="\[\e[1;31m\]\u@\h \[\e[1;33m\]\w\[\e[0m\] $(starship prompt) \$ "'
prompt3='PS1="\[\e[1;36m\]\u@\h \[\e[1;35m\]\w\[\e[0m\] $(starship prompt) \$ "'
prompt4='PS1="\[\e[1;32m\]\u@\h \[\e[1;34m\]→ \[\e[0m\]$(starship prompt) \$ "'
prompt5='PS1="\[\e[1;31m\]\u@\h \[\e[1;33m\]→ \[\e[0m\]$(starship prompt) \$ "'
prompt6='PS1="\[\e[1;36m\]\u@\h \[\e[1;35m\]→ \[\e[0m\]$(starship prompt) \$ "'
prompt_none='PS1="\$ "'  # Plain shell prompt

# Display bash prompts to user
echo "Please choose a bash prompt:"
echo "1) Green and Blue: $prompt1"
echo "2) Red and Yellow: $prompt2"
echo "3) Cyan and Magenta: $prompt3"
echo "4) Green with Arrow: $prompt4"
echo "5) Red with Arrow: $prompt5"
echo "6) Cyan with Arrow: $prompt6"
echo "7) None (Plain Shell Prompt)"
read -p "Enter the number of your choice: " choice

# Apply the chosen bash prompt
case $choice in
    1)
        echo "$prompt1" >> ~/.bashrc
        ;;
    2)
        echo "$prompt2" >> ~/.bashrc
        ;;
    3)
        echo "$prompt3" >> ~/.bashrc
        ;;
    4)
        echo "$prompt4" >> ~/.bashrc
        ;;
    5)
        echo "$prompt5" >> ~/.bashrc
        ;;
    6)
        echo "$prompt6" >> ~/.bashrc
        ;;
    7)
        echo "$prompt_none" >> ~/.bashrc
        ;;
    *)
        echo "Invalid choice. Applying default prompt (Plain Shell Prompt)."
        echo "$prompt_none" >> ~/.bashrc
        ;;
esac

# Configure bash prompt with Starship
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# Run Fastfetch on bash start
echo 'fastfetch' >> ~/.bashrc

# Ask user for font choice
echo "Which font would you like to use for your terminal?"
echo "1) Fira Code"
echo "2) Meslo"
read -p "Enter the number of your choice: " font_choice

# Set font size (example: 12)
read -p "Enter the font size (e.g., 12): " font_size

# Save font choice and size to a configuration file (example: ~/.font_config)
echo "font_family=${font_choice}" >> ~/.font_config
echo "font_size=${font_size}" >> ~/.font_config

# Ask user if they want auto-completion
read -p "Do you want to enable auto-completion? (y/n): " auto_complete_choice

if [[ "$auto_complete_choice" == "y" || "$auto_complete_choice" == "Y" ]]; then
    echo 'if [ -f /etc/bash_completion ]; then' >> ~/.bashrc
    echo '    . /etc/bash_completion' >> ~/.bashrc
    echo 'fi' >> ~/.bashrc
    echo "Auto-completion has been enabled."
else
    echo "Auto-completion will not be enabled."
fi

echo "Starship, Zoxide, Fastfetch, fonts, and configurations have been installed successfully."
echo "Please restart your terminal or run 'source ~/.bashrc' to apply the changes."