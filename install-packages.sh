#!/usr/bin/env bash
# Auchlinux System & Packages Bootstrap Script

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "\n${BLUE}[+] $*${NC}\n"; }
warn() { echo -e "\n${YELLOW}[!] $*${NC}\n"; }
error() { echo -e "\n${RED}[✗] ERROR: $*${NC}\n" >&2; exit 1; }

# Verify we are NOT running as root (since yay/paru AUR helpers cannot run as root)
if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root! Sudo permissions will be requested when needed."
fi

# Ensure running in Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    error "This script is designed for Arch Linux only."
fi

# 1. Update pacman databases
info "Updating Arch package databases..."
sudo pacman -Sy

# 2. Check/Install AUR helper (yay)
info "Checking for AUR Helper..."
AUR_HELPER=""
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    info "Found 'yay' as AUR helper."
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    info "Found 'paru' as AUR helper."
else
    warn "No AUR helper found. Installing 'yay' from source..."
    sudo pacman -S --needed --noconfirm base-devel git
    
    build_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$build_dir"
    cd "$build_dir"
    makepkg -si --noconfirm
    cd - >/dev/null
    rm -rf "$build_dir"
    
    AUR_HELPER="yay"
    info "Successfully installed 'yay'."
fi

# 3. Official packages to install
OFFICIAL_PKGS=(
    # Compositor & Shell Environment
    hyprland
    waybar
    rofi
    swaync
    hyprlock
    hypridle
    hyprpolkitagent
    hyprpicker
    awww
    uwsm
    
    # Core User Space Applications
    kitty
    dolphin
    keepassxc
    imv
    mpv
    cava
    code
    neovim
    yazi
    chromium
    signal-desktop
    telegram-desktop
    discord
    
    # System Command Utilities
    fastfetch
    starship
    zsh
    btop
    jq
    rsync
    curl
    wget
    pamixer
    playerctl
    libnotify
    brightnessctl
    network-manager-applet
    flatpak
    pacman-contrib
    udiskie
    unzip
    fzf
    
    # Additional CLI Utilities (used by scripts & zsh configs)
    eza
    zoxide
    bat
    ripgrep
    fd
    duf
    wtype
    cliphist
    arch-audit
    hyprsunset
    wf-recorder
    pavucontrol
    power-profiles-daemon
    xdg-utils
    
    # Clipboard & Screenshot Stack
    grim
    slurp
    swappy
    satty
    wl-clipboard
    wl-clip-persist
    tesseract
    tesseract-data-eng
    zbar
    
    # Theme & Display managers
    nwg-look
    nwg-displays
    qt5ct
    qt6ct
    kvantum
    kvantum-qt5
    imagemagick
    xsettingsd
    papirus-icon-theme
    matugen
    rofi-calc
    
    # Portal support (Screen sharing/file pickers)
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    
    # Audio server configuration
    wireplumber
    pipewire
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    pipewire-audio
    gst-plugin-pipewire
    
    # Bluetooth stack
    bluez
    bluez-utils
    blueman
    
    # Zsh configuration plugins
    zsh-autosuggestions
    zsh-syntax-highlighting
    
    # Fonts
    ttf-jetbrains-mono-nerd
    inter-font
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji

    # Camera & webcam (physical webcam + phone-as-webcam pipeline)
    v4l-utils              # v4l2-ctl: list/configure capture devices
    v4l2loopback-dkms      # virtual /dev/video for phone/OBS virtual cameras
    linux-zen-headers      # required to build the v4l2loopback dkms module (zen kernel)
    guvcview               # GUI webcam viewer / control panel
    obs-studio             # advanced capture/streaming + virtual camera
    scrcpy                 # phone mirroring + USB camera source (--v4l2-sink)
    android-tools          # adb: USB/Wi-Fi device bridge for scrcpy & port-forward
)

# 4. AUR packages to install
AUR_PKGS=(
    pyprland
    ttf-material-symbols-variable-git
    zsh-256color
    grimblast-git
    droidcam                # phone-as-webcam client (Wi-Fi/USB)
    sndcpy                  # forward Android audio over USB (older phones; scrcpy 2.0+ does it natively)
    localsend-bin           # cross-platform Wi-Fi file sharing (prebuilt; avoids long Flutter build)
)

# Install official packages
info "Installing official packages via pacman..."
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

# Install AUR packages
info "Installing AUR packages via ${AUR_HELPER}..."
$AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}"

# 5. Flatpak configuration and Brave Browser
info "Configuring Flatpak and installing Brave Browser..."
# Add Flathub repository if it doesn't exist
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Brave Browser via Flatpak
flatpak install --user flathub com.brave.Browser -y

# 6. Prompt to set up Steam/Gaming packages
echo
read -p "Do you want to run the Steam + Vulkan GPU drivers setup script? (y/N): " -n 1 -r REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -f "./scripts/steam.sh" ]]; then
        info "Running Steam & graphics setup..."
        chmod +x ./scripts/steam.sh
        ./scripts/steam.sh
    else
        warn "Could not find './scripts/steam.sh'. Skipping Steam setup."
    fi
fi

# 7. Apply dotfiles configurations using apply-config.sh
if [[ -f "./scripts/apply-config.sh" ]]; then
    info "Applying repository dotfiles/configs to ~/.config..."
    chmod +x ./scripts/apply-config.sh
    ./scripts/apply-config.sh
fi

# 8. Install Custom Nerd Fonts if archive exists
FONTS_TAR="./scripts/assets/Custom_Nerd_Fonts.tar.gz"
TARGET_DIR="$HOME/.local/share/fonts"
if [[ -f "$FONTS_TAR" ]]; then
    info "Installing custom Nerd Fonts..."
    mkdir -p "$TARGET_DIR"
    tar -xzf "$FONTS_TAR" -C "$TARGET_DIR"
    fc-cache -f "$TARGET_DIR"
    info "Custom Nerd Fonts installed successfully."
fi

# 9. v4l2loopback virtual webcam — auto-create a /dev/video10 "Phone Camera"
#    so phone-camera.sh can stream into it without needing sudo at runtime.
if pacman -Qq v4l2loopback-dkms &>/dev/null; then
    info "Configuring v4l2loopback virtual webcam (/dev/video10)..."
    echo 'options v4l2loopback devices=1 video_nr=10 card_label="Phone Camera" exclusive_caps=1' \
        | sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null
    echo 'v4l2loopback' | sudo tee /etc/modules-load.d/v4l2loopback.conf >/dev/null
    sudo modprobe v4l2loopback 2>/dev/null \
        && info "v4l2loopback loaded (virtual cam ready; persists across reboots)." \
        || warn "v4l2loopback will load on next reboot (module just built by dkms)."
fi

info "Bootstrap complete! Reboot now to load into Hyprland."
