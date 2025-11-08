#!/bin/bash
# Automated Arch Linux Daily Driver Setup Script
#
# This script handles package installation, user configuration, and system hardening
# for a fresh Arch Linux install.
#
# USAGE: chmod +x install.sh && sudo ./install.sh
# REQUIREMENTS: Run as root or with sudo. Ensure internet is connected.
# LOGS: Check /tmp/arch_setup.log for details.

## ------------------------------------------------------------------------------
## 🎯 GLOBAL CONFIGURATION AND VARIABLES
## ------------------------------------------------------------------------------

# Package Definitions
CORE_PACKAGES=(
    "git" "vim" "btop" "neovim" "fish" "curl" "wget" "man-db"
    "firefox" "xfce4" "xfce4-goodies" "ly" "networkmanager" "alsa-utils"
    "pulseaudio" "pulseaudio-alsa" "xdg-user-dirs" "ttf-dejavu"
)
AUR_PACKAGES=(
    "discord"
    "spotify"
)

# Global Settings
LOG_FILE="/tmp/arch_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1  # Log all output

# User Detection (Must run before any user-specific functions are defined)
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(logname 2>/dev/null || whoami)"
fi
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"


## ------------------------------------------------------------------------------
## 🛡️ GUARDS AND TRAPS (Security & Error Handling)
## ------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status.
set -e

# Trap errors and provide a descriptive message.
trap 'echo "🚨 ERROR: Script failed at line $LINENO. Check $LOG_FILE for details." >&2; exit 1' ERR

# Ensure the script is run as root for pacman and systemctl operations
if [[ $EUID -ne 0 ]]; then
    echo "⚠️ This script must be run as root (e.g., sudo ./install.sh) for pacman and systemctl commands."
    exit 1
fi


## ------------------------------------------------------------------------------
## ⚙️ FUNCTIONS (All Logic is Encapsulated Here)
## ------------------------------------------------------------------------------

function safety_check() {
    echo "" 
    echo "🚨 SAFETY WARNING 🚨"
    echo "This script will make permanent changes to your system, including installing packages and configuring services."
    echo "It assumes you are running a FRESH Arch Linux base install."
    

    read -p "Have you read the README.md and understand the risks? (y/N): " -n 1 response
    echo "" 
    
    if [[ "$response" != "y" ]] && [[ "$response" != "Y" ]]; then
        echo "Exiting script. Please read the documentation before proceeding."
        exit 1
    fi
    echo "✅ Proceeding with setup..."
    echo "" 
}

function check_internet() {
    echo "🌐 Checking internet connection..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "✅ Internet connection is active."
    else
        echo "❌ Internet connection failed. Please check your network setup."
        exit 1
    fi
}

function install_core_packages() {
    echo "📦 Installing core packages..."
    pacman -Syu --needed --noconfirm "${CORE_PACKAGES[@]}"
    if [[ $? -eq 0 ]]; then
        echo "✅ Core packages installed successfully."
    else
        echo "❌ Failed to install core packages. Check pacman logs."
        exit 1
    fi
}

function install_aur_helper() {
    local AUR_HELPER="yay"
    local BUILD_DIR="$REAL_HOME/builds/$AUR_HELPER"
    
    echo "🔨 Installing AUR helper ($AUR_HELPER) as non-root user $REAL_USER..."
    
    # 1. Install prerequisites (as root/sudo)
    pacman -S --needed --noconfirm git base-devel
    
    # 2. Clone and build (MUST be done as the non-root user)
    sudo -u "$REAL_USER" bash -c "
        mkdir -p '$REAL_HOME/builds'
        git clone 'https://aur.archlinux.org/$AUR_HELPER.git' '$BUILD_DIR' || exit 1
        cd '$BUILD_DIR'
        makepkg -si --noconfirm || exit 1
    " || {
        echo "❌ AUR helper build or installation failed (ran as $REAL_USER). Check the output."
        rm -rf "$BUILD_DIR"
        exit 1
    }
    
    # 3. Clean up (as root/sudo)
    rm -rf "$BUILD_DIR"
    echo "✅ $AUR_HELPER installed and build files cleaned up."
}

function install_aur_packages() {
    echo "📦 Installing AUR packages: ${AUR_PACKAGES[*]}..."
    if command -v yay &> /dev/null; then
        # Run AUR installs as the real user to ensure proper permissions for configs
        sudo -u "$REAL_USER" yay -S --noconfirm "${AUR_PACKAGES[@]}" || { echo "❌ Failed to install some AUR packages."; }
    else
        echo "⚠️ AUR helper not available. Skipping AUR packages."
    fi
    echo "✅ AUR package installation attempted."
}

function finalize_user_setup() {
    echo "⚙️ Finalizing user setup for $REAL_USER..."
    local FISH_PATH="/usr/bin/fish"

    if ! id -u "$REAL_USER" &>/dev/null; then
        echo "❌ User '$REAL_USER' does not exist. Cannot configure shell or XDG directories."
        return
    fi
    
    # Set fish as default shell
    if grep -q "$FISH_PATH" /etc/shells; then
        if [[ "$(getent passwd "$REAL_USER" | cut -d: -f7)" != "$FISH_PATH" ]]; then
            chsh -s "$FISH_PATH" "$REAL_USER" || echo "⚠️ Failed to change shell for $REAL_USER."
        else
            echo "  - Shell is already fish for $REAL_USER. Skipping."
        fi
    fi
    
    # Enable essential services
    systemctl enable NetworkManager.service
    systemctl enable ly.service || echo "⚠️ Failed to enable ly.service."
    
    # Initialize XDG directories for the user (MUST run as the user)
    sudo -u "$REAL_USER" xdg-user-dirs-update --force
    echo "✅ Enabled NetworkManager and configured user directories."
}

function run_maintenance() {
    echo "🧹 Running post-installation system maintenance..."
    
    echo "  - Removing orphaned packages..."
    pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true

    echo "  - Cleaning pacman cache (keeping only installed packages)..."
    pacman -Sc --noconfirm

    if command -v yay &> /dev/null; then
        echo "  - Cleaning AUR build cache with yay..."
        yay -Sc --noconfirm 2>/dev/null || true
    fi
    
    echo "✅ System maintenance complete."
}


## ------------------------------------------------------------------------------
## 🚀 MAIN EXECUTION FLOW
## ------------------------------------------------------------------------------

function main() {
    echo "🚀 Starting Arch Linux setup..."
    safety_check
    check_internet
    install_core_packages
    install_aur_helper
    install_aur_packages
    finalize_user_setup
    run_maintenance
    
    echo "--- Setup Complete! ---"
    echo "NOTE: You may need to reboot for the display manager and new shell to take effect."
    echo "Logs saved to $LOG_FILE."
    read -p "Reboot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
    echo "Have fun with your newly functional environment!"
}

main
