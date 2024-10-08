#!/bin/bash

# Script to enable IOMMU, install virtualization tools, and set up network bridge by gjm

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define rainbow colors
COLORS=("\033[38;5;196m" "\033[38;5;202m" "\033[38;5;226m" "\033[38;5;082m" "\033[38;5;021m" "\033[38;5;093m")
NC='\033[0m' # No Color

# Rainbow text function
rainbow_echo() {
    text="$1"
    for (( i=0; i<${#text}; i++ )); do
        color_index=$((i % ${#COLORS[@]}))
        echo -en "${COLORS[$color_index]}${text:$i:1}"
    done
    echo -e "$NC"
}

# Function to enable IOMMU in bootloader
enable_iommu() {
    if [ -d "/boot/grub" ]; then
        echo -e "${BLUE}Detected GRUB. Updating GRUB configuration...${NC}"
        sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ intel_iommu=on iommu=pt"/' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    elif [ -d "/boot/loader" ]; then
        echo -e "${BLUE}Detected systemd-boot. Updating kernel parameters...${NC}"
        for conf in /boot/loader/entries/*.conf; do
            if ! grep -q "intel_iommu=on iommu=pt" "$conf"; then
                sudo sed -i '/^options/ s/$/ intel_iommu=on iommu=pt/' "$conf"
            fi
        done
    elif [ -f "/boot/efi/EFI/refind/refind.conf" ]; then
        echo -e "${BLUE}Detected rEFInd. Updating kernel parameters...${NC}"
        if ! grep -q "intel_iommu=on iommu=pt" /boot/efi/EFI/refind/refind.conf; then
            sudo sed -i '/^"Boot with standard options"/ s/"$/ intel_iommu=on iommu=pt"/' /boot/efi/EFI/refind/refind.conf
        fi
    elif [ -f "/boot/syslinux/syslinux.cfg" ]; then
        echo -e "${BLUE}Detected SYSLINUX. Updating kernel parameters...${NC}"
        if ! grep -q "intel_iommu=on iommu=pt" /boot/syslinux/syslinux.cfg; then
            sudo sed -i '/^APPEND/ s/$/ intel_iommu=on iommu=pt/' /boot/syslinux/syslinux.cfg
        fi
    else
        echo -e "${RED}Unknown bootloader detected. Please manually add 'intel_iommu=on iommu=pt' to your kernel parameters.${NC}"
    fi
}

# Enable IOMMU
echo -e "${YELLOW}Enabling IOMMU...${NC}"
enable_iommu

# Install virtualization tools
echo -e "${YELLOW}Installing virt-manager and QEMU...${NC}"
sudo pacman -S --noconfirm virt-manager qemu qemu-arch-extra libvirt edk2-ovmf dnsmasq

# Add current user to libvirt group
echo -e "${YELLOW}Adding current user to libvirt group...${NC}"
sudo usermod -aG libvirt $USER

# Enable and start libvirtd service
echo -e "${YELLOW}Enabling and starting libvirtd service...${NC}"
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service

# Create and start virsh bridge network
echo -e "${YELLOW}Creating and starting virsh bridge network...${NC}"
sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
sudo virsh net-start default
sudo virsh net-autostart default

echo -e "${GREEN}Setup complete. Please reboot your system for changes to take effect.${NC}"
echo -e "${GREEN}After reboot, you may need to log out and log back in for group changes to apply.${NC}"

