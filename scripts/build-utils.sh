#!/bin/bash

# ANSI color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored text
# $1: Color code
# $2: Text to print
print_color() {
    printf "${1}%s${NC}\n" "${2}"
}

# Function to detect the Linux distribution
# Returns the distribution ID (e.g., ubuntu, fedora, arch)
detect_distro() {
    if [ -f /etc/os-release ]; then
        # Most modern distributions use /etc/os-release
        . /etc/os-release
        echo $ID
    elif [ -f /etc/lsb-release ]; then
        # Some Ubuntu-based distributions might use this
        . /etc/lsb-release
        echo $DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        # Debian-based distributions
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        # Red Hat-based distributions
        echo "redhat"
    else
        # If unable to detect, return unknown
        echo "unknown"
    fi
}

# Function to install packages based on the distribution
# $1: Distribution name
install_build_utils() {
    local distro=$1
    print_color $CYAN "This is a build utilities install script by Tech Logicals"
    print_color $YELLOW "Installing build utilities for $distro..."

    # Install basic build utilities based on the distribution
    case $distro in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y build-essential gcc g++ make automake autoconf libtool pkg-config cmake git
            ;;
        fedora|centos|rhel)
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y gcc gcc-c++ make automake autoconf libtool pkgconfig cmake git
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm base-devel gcc make automake autoconf libtool pkgconf cmake git
            ;;
        opensuse*)
            sudo zypper install -y -t pattern devel_basis
            sudo zypper install -y gcc gcc-c++ make automake autoconf libtool pkg-config cmake git
            ;;
        *)
            print_color $RED "Unsupported distribution: $distro"
            print_color $YELLOW "Please install the build utilities manually."
            exit 1
            ;;
    esac

    # Install additional handy build tools
    print_color $BLUE "Installing additional handy build tools..."
    case $distro in
        ubuntu|debian)
            sudo apt-get install -y clang llvm gdb valgrind ccache ninja-build meson \
                cppcheck clang-tidy clang-format bear doxygen graphviz \
                lcov gcovr cmake-curses-gui qtbase5-dev qttools5-dev
            ;;
        fedora|centos|rhel)
            sudo dnf install -y clang llvm gdb valgrind ccache ninja-build meson \
                cppcheck clang-tools-extra bear doxygen graphviz \
                lcov gcovr cmake-gui qt5-qtbase-devel qt5-qttools-devel
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm clang llvm gdb valgrind ccache ninja meson \
                cppcheck clang bear doxygen graphviz \
                lcov gcovr cmake qt5-base qt5-tools
            ;;
        opensuse*)
            sudo zypper install -y clang llvm gdb valgrind ccache ninja meson \
                cppcheck clang-tools bear doxygen graphviz \
                lcov gcovr cmake-gui libqt5-qtbase-devel libqt5-qttools-devel
            ;;
    esac
}

# Main script execution starts here
print_color $MAGENTA "=== Build Utilities Installation Script by Tech Logicals ==="

# Detect the Linux distribution
DISTRO=$(detect_distro)
print_color $GREEN "Detected distribution: $DISTRO"

# Install build utilities and additional tools
install_build_utils $DISTRO

print_color $MAGENTA "Installation complete!"
print_color $YELLOW "You may need to log out and log back in for some changes to take effect."

# Provide a brief explanation of the installed tools
print_color $CYAN "Installed tools include:"
echo "- Basic build utilities: gcc, g++, make, automake, autoconf, libtool, pkg-config, cmake, git"
echo "- Additional tools: clang, llvm, gdb, valgrind, ccache, ninja-build, meson"
echo "- Static analysis: cppcheck, clang-tidy"
echo "- Code formatting: clang-format"
echo "- Documentation: doxygen, graphviz"
echo "- Code coverage: lcov, gcovr"
echo "- GUI tools: cmake-gui, Qt development libraries"
print_color $YELLOW "For more information on how to use these tools, refer to their respective documentation."