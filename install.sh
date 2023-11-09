#!/usr/bin/env bash

INSTALL_DIR="${HOME:-/home/default}"
CONFIG_DIR="$HOME/.config/nvim"
PLUGIN_DIR="$HOME/.local/share/nvim"

# set platform specific download link and install directory
INSTALL_LINK="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
TAR_DIR="nvim-linux64"
platform=$(uname -a | awk '{print $1;}' | head -n 1)
if [ "$platform" = "Darwin" ]; then
    INSTALL_LINK="https://github.com/neovim/neovim/releases/latest/download/nvim-macos.tar.gz"
    TAR_DIR="nvim-macos"
fi

# helpers for colorful output
green=$(tput setaf 2); yellow=$(tput setaf 3); red=$(tput setaf 1); normal=$(tput sgr0)
function printgln () {
  printf '%s%s%s\n' "${green}" "$1" "${normal}"
}
function printyln () {
  printf '%s%s%s\n' "${yellow}" "$1" "${normal}"
}
function printrln () {
  printf '%s%s%s\n' "${red}" "$1" "${normal}"
}

function yes_or_no () {
    while true; do
        read -rp "$* [y/N]: ${normal}" yn
        case $yn in
            [Yy]*) return 0;;  
            *) return  1;;
        esac
    done
}

function should_abort () {
    while true; do
        read -rp "$* [y/N]: ${normal}" yn
        case $yn in
            [Yy]*) return 0;;  
            *) printrln "Aborted!"; exit 1;;
        esac
    done
}

function install_neovim () {
  if [ -d "$INSTALL_DIR/$TAR_DIR" ]; then
    printyln "$INSTALL_DIR/$TAR_DIR already exists. Would you like to update Neovim?" 
    if yes_or_no "${red}WARNING: This will remove your existing installation! Continue?"; then
      printyln "Removing prior neovim installation..."
      rm -rf "${INSTALL_DIR:?/home/default}/${TAR_DIR:?nvim}"
      rm -rf "$PLUGIN_DIR"
    else
      return 1
    fi 
  fi
  printgln 'Fetching Neovim...'
  mkdir -p "$INSTALL_DIR"
  curl -L -o "$INSTALL_DIR/nvim.tar.gz" "$INSTALL_LINK" 
  tar -zxf "$INSTALL_DIR/nvim.tar.gz" -C "$INSTALL_DIR"
  rm "$INSTALL_DIR/nvim.tar.gz"
  cmd="$INSTALL_DIR/$TAR_DIR/bin/nvim --version"
  check=$(eval "$cmd" | awk '{print $1;}' | head -n 1)
  printgln "Updating config at $HOME/.config/nvim"
  if [ "$check" != "NVIM" ]; then
    printrln "Could not verify nvim installation!"
    return 1
  fi
  printgln "Neovim installation complete. Plugins will be installed when Neovim is started for the first time."
  return 0
}

function install_config () {
  if [ -d "$CONFIG_DIR" ]; then
    printyln "$CONFIG_DIR already exists. Would you like to update your config?" 
    if yes_or_no "${red}WARNING: This will remove your existing config! Continue?"; then
      printyln "Removing prior neovim config..."
      rm -rf "$CONFIG_DIR"
    else
      return 1 
    fi 
  fi
  printgln "Fetching config..."
  git clone https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1
  git clone https://github.com/aWindsweptEmu/NvGigaChad-Config "$HOME/.config/nvim/lua/custom" --depth 1
  printgln "Configuration installation complete."
  return 0
}

function abort () {
  printrln "Aborted!"; exit 1
}

# run installations
printf "\n"
if [ $# -eq 0 ]; then
    should_abort "${yellow}No installation path provided, defaulting to $INSTALL_DIR. Continue?"
  else
    INSTALL_DIR=$1
    should_abort "${yellow}Installing Neovim to $INSTALL_DIR. Continue?"
fi

printf "\n"
install_neovim
neovim_installed=$?
printf "\n"
install_config
if [ "$neovim_installed" = "0" ]; then
  printf "\n"
  printgln "Make sure to add Neovim to your path: export PATH=\$PATH:$INSTALL_DIR/$TAR_DIR/bin"
fi
