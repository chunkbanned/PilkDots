#!/bin/bash

# Exit the script if any command fails
set -e

# Function to configure NVIDIA settings if the user is using an NVIDIA GPU
configure_nvidia() {
  echo "Configuring NVIDIA settings..."

  # Edit /etc/mkinitcpio.conf
  sudo sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

  # Create/edit /etc/modprobe.d/nvidia.conf
  echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf

  # Run mkinitcpio
  sudo mkinitcpio -P

  # Add NVIDIA-specific configurations to hyprland.conf
  echo "Adding NVIDIA-specific configurations to ~/.config/hypr/hyprland.conf"
  echo -e "\n# NVIDIA-specific settings" >> ~/.config/hypr/hyprland.conf
  echo "env = LIBVA_DRIVER_NAME,nvidia" >> ~/.config/hypr/hyprland.conf
  echo "env = XDG_SESSION_TYPE,wayland" >> ~/.config/hypr/hyprland.conf
  echo "env = GBM_BACKEND,nvidia-drm" >> ~/.config/hypr/hyprland.conf
  echo "env = __GLX_VENDOR_LIBRARY_NAME,nvidia" >> ~/.config/hypr/hyprland.conf
  echo -e "\ncursor {" >> ~/.config/hypr/hyprland.conf
  echo "    no_hardware_cursors = true" >> ~/.config/hypr/hyprland.conf
  echo "}" >> ~/.config/hypr/hyprland.conf

  echo "NVIDIA configuration completed. You will need to restart your system at the end of the installation."
}

# Function to install fonts
install_fonts() {
  echo "Installing fonts..."

  # Create fonts directory if it doesn't exist
  fonts_dir="$HOME/.local/share/fonts"
  mkdir -p "$fonts_dir"

  # Download and install each font
  echo "Downloading and installing Fira Sans Semibold..."
  wget -qO "$fonts_dir/FiraSans-Semibold.ttf" "https://github.com/google/fonts/raw/main/ofl/firasans/FiraSans-SemiBold.ttf"

  echo "Downloading and installing Font Awesome 6 Free..."
  wget -qO "$fonts_dir/FontAwesome6Free-Regular.otf" "https://github.com/FortAwesome/Font-Awesome/raw/6.x/webfonts/fa-regular-400.otf"

  echo "Downloading and installing FontAwesome..."
  wget -qO "$fonts_dir/FontAwesome-Regular.ttf" "https://github.com/FortAwesome/Font-Awesome/raw/6.x/webfonts/fa-solid-900.otf"

  echo "Downloading and installing Roboto..."
  wget -qO "$fonts_dir/Roboto-Regular.ttf" "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf"

  # Download Helvetica from the provided link, extract it, and keep only Helvetica.ttf
  echo "Downloading and extracting Helvetica..."
  temp_dir=$(mktemp -d)
  wget -qO "$temp_dir/helvetica.zip" "https://dn.freefontsfamily.org/download/helvetica-font"
  unzip -q "$temp_dir/helvetica.zip" -d "$temp_dir"
  find "$temp_dir" -name 'Helvetica.ttf' -exec mv {} "$fonts_dir/" \;
  rm -rf "$temp_dir"  # Clean up the temporary directory

  echo "Helvetica installed successfully!"

  echo "Downloading and installing Arial..."
  wget -qO "$fonts_dir/Arial.ttf" "https://github.com/kavin808/arial.ttf/raw/refs/heads/master/arial.ttf"

  echo "Downloading and installing DroidSansMono..."
  wget -qO "$fonts_dir/DroidSansMono-Regular.ttf" "https://github.com/google/fonts/raw/main/apache/droidsansmono/DroidSansMono-Regular.ttf"

  echo "Downloading and installing Material Symbols Outlined..."
  wget -qO "$fonts_dir/MaterialSymbolsOutlined-Regular.ttf" "https://github.com/google/fonts/raw/main/apache/materialsymbolsoutlined/MaterialSymbolsOutlined-Regular.ttf"

  # Refresh font cache
  echo "Refreshing font cache..."
  fc-cache -fv

  echo "Fonts installed successfully!"
}

# Install or update dependencies using yay
install_dependencies() {
  echo "Installing dependencies with yay..."
  
  # Ensure yay is installed
  if ! command -v yay &> /dev/null; then
    echo "yay not found. Installing yay..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
  fi

  # Update system and install necessary packages
  yay -Syu --needed hyprland wlogout waypaper waybar swww rofi swaync thunar kitty \
    pavucontrol gtk3 gtk2 xcur2png gsettings nwg-look fastfetch zsh oh-my-zsh-git \
    hyprshot networkmanager networkmanager-qt nm-connection-editor
}

# Clone the dotfiles repository and move the necessary files
setup_dotfiles() {
  echo "Cloning the PilkDots repository..."
  
  if [ ! -d "$HOME/PilkDots" ]; then
    git clone https://github.com/PilkDrinker/PilkDots
  else
    echo "Repository already exists. Pulling latest changes..."
    cd PilkDots
    git pull
    cd ..
  fi

  # Move necessary directories to home directory
  echo "Moving .config, .themes, and wallpaper to home directory..."
  cp -r PilkDots/.config ~/
  cp -r PilkDots/.themes ~/
  cp -r PilkDots/wallpaper ~/

  echo "Dotfiles setup completed!"
}

# Check if the user is using an NVIDIA GPU
check_nvidia() {
  echo "Checking for NVIDIA GPU..."

  if lspci | grep -i nvidia &> /dev/null; then
    echo "NVIDIA GPU detected."
    read -p "Do you want to apply NVIDIA-specific configurations? (y/n) " answer
    case $answer in
      [Yy]* ) configure_nvidia;;
      [Nn]* ) echo "Skipping NVIDIA configuration.";;
      * ) echo "Please answer yes or no.";;
    esac
  else
    echo "No NVIDIA GPU detected. Skipping NVIDIA configuration."
  fi
}

# Main script execution
main() {
  install_dependencies
  setup_dotfiles
  install_fonts
  check_nvidia

  echo "All steps completed! If you configured for NVIDIA, please restart your system for changes to take effect."
}

# Run the main function
main

