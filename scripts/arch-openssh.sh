#!/bin/bash

# Script to open SSH port for remote logins on Arch Linux

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Install OpenSSH if not already installed
if ! pacman -Qs openssh > /dev/null; then
    echo "Installing OpenSSH..."
    pacman -Sy --noconfirm openssh
fi

# Enable and start SSH service
echo "Enabling and starting SSH service..."
systemctl enable sshd
systemctl start sshd

# Open port 22 in firewall (assuming ufw is used)
if command -v ufw &> /dev/null; then
    echo "Opening port 22 in UFW firewall..."
    ufw allow 22/tcp
    ufw reload
else
    echo "UFW firewall not found. Please manually configure your firewall to allow port 22."
fi

# Verify SSH port is open
if ss -tuln | grep :22 > /dev/null; then
    echo "SSH port 22 is now open and listening for connections."
else
    echo "Error: SSH port 22 is not open. Please check your configuration."
fi

echo "Script completed. SSH should now be accessible for remote logins."
echo "Remember to set a strong password for your user account and consider using key-based authentication for better security."
