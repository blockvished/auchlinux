#!/usr/bin/env bash

# Steam + Proton setup script for Arch Linux
# Run with: chmod +x steam-setup.sh && ./steam-setup.sh

set -e

echo "========================================="
echo " Steam + Proton Setup for Arch Linux"
echo "========================================="
echo

# Detect package manager
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
else
    AUR_HELPER=""
fi

# Enable multilib if not enabled
echo "[1/6] Checking multilib repository..."

if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    sudo sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
else
    echo "Multilib already enabled."
fi

# Update package database
echo
echo "[2/6] Updating system packages..."
sudo pacman -Syu --noconfirm

# Install graphics drivers
echo
echo "[3/6] Installing Vulkan + graphics support..."

GPU_VENDOR=$(lspci | grep -E "VGA|3D")

if echo "$GPU_VENDOR" | grep -qi "nvidia"; then
    echo "NVIDIA GPU detected."
    sudo pacman -S --needed --noconfirm \
        nvidia-utils \
        lib32-nvidia-utils \
        vulkan-icd-loader \
        lib32-vulkan-icd-loader
elif echo "$GPU_VENDOR" | grep -qi "amd"; then
    echo "AMD GPU detected."
    sudo pacman -S --needed --noconfirm \
        mesa \
        lib32-mesa \
        vulkan-radeon \
        lib32-vulkan-radeon \
        vulkan-icd-loader \
        lib32-vulkan-icd-loader \
        lib32-glibc \
        vulkan-tools \
        mesa-utils \
        mesa-demos \
        linux-firmware
elif echo "$GPU_VENDOR" | grep -qi "intel"; then
    echo "Intel GPU detected."
    sudo pacman -S --needed --noconfirm \
        mesa \
        lib32-mesa \
        vulkan-intel \
        lib32-vulkan-intel \
        vulkan-icd-loader \
        lib32-vulkan-icd-loader
else
    echo "Unknown GPU. Installing generic Vulkan packages..."
    sudo pacman -S --needed --noconfirm \
        mesa \
        lib32-mesa \
        vulkan-icd-loader \
        lib32-vulkan-icd-loader
fi

# Install Steam
echo
echo "[4/6] Installing Steam..."
sudo pacman -S --needed --noconfirm steam

# Install Proton-GE
echo
echo "[5/6] Installing Proton-GE..."

if [ -n "$AUR_HELPER" ]; then
    $AUR_HELPER -S --needed --noconfirm proton-ge-custom-bin
else
    echo "No AUR helper found."
    echo "Install paru or yay if you want Proton-GE."
fi

# Extra gaming tools
echo
echo "[6/6] Installing extra gaming utilities..."

sudo pacman -S --needed --noconfirm \
    gamemode \
    lib32-gamemode \
    mangohud \
    lib32-mangohud \
    gamescope

echo
echo "========================================="
echo " Setup Complete!"
echo "========================================="
echo
echo "Next steps:"
echo "1. Launch Steam"
echo "2. Login"
echo "3. Go to:"
echo "   Steam > Settings > Compatibility"
echo "4. Enable:"
echo "   ✓ Enable Steam Play for supported titles"
echo "   ✓ Enable Steam Play for all other titles"
echo "5. Select Proton-GE or Proton Experimental"
echo
echo "========================================="
echo " 🎮 Counter-Strike 2 (CS2) Optimizations"
echo "========================================="
echo
echo "Recommended Steam Launch Options:"
echo "  gamemoderun %command% -novid -nojoy -fullscreen +fps_max 120"
echo
echo "AMD Performance Option (utilizing ACO shader compiler):"
echo "  RADV_PERFTEST=aco gamemoderun %command% -novid -nojoy -fullscreen +fps_max 120"
echo
echo "Running under Wayland (Native):"
echo "To bypass Xwayland for lower input latency, you can run CS2 natively on Wayland"
echo "by adding this environment variable to your Steam Launch Options:"
echo "  SDL_VIDEODRIVER=wayland gamemoderun %command% -novid -nojoy -fullscreen +fps_max 120"
echo
echo "Alternatively, you can run it via Gamescope (Valve's Wayland micro-compositor):"
echo "  gamescope -W 1280 -H 720 -r 120 -F fsr -- gamemoderun %command% -novid -nojoy -fullscreen +fps_max 120"
echo
echo "Recommended In-Game Settings (Ryzen 5 5500U / Vega 7):"
echo "  - Resolution: 1280x720"
echo "  - FSR: ON (Quality or Balanced)"
echo "  - Global Shadow Quality: Low"
echo "  - MSAA: Off"
echo "  - Ambient Occlusion: Off"
echo "  - V-Sync: Off"
echo
echo "Note: The first few runs may stutter due to background shader compilation."
echo "Using the Zen kernel provides a smoother frametime distribution!"
echo

# gamemoderun %command% -novid -nojoy -fullscreen +fps_max 120