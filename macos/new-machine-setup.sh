#!/bin/bash

boldGreen="\033[1;32m"
boldYellow="\033[1;33m"
boldRed="\033[1;31m"
boldPurple="\033[1;35m"
boldBlue="\033[1;34m"
noColor="\033[0m"

clear

GIT_USER_EMAIL="jonathanmorris678@gmail.com"
GIT_USER_NAME="Jonathan Morris"

echo
echo "########################################################################"
echo "Installing xcode-select"
echo "########################################################################"

if ! xcode-select -p &>/dev/null; then
  # In the [brew documentation](https://docs.brew.sh/Installation)
  # you can see the MacOS Requirements
  echo
  echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
  echo "Installing xcode-select, this will take some time..."
  echo -e "${boldYellow}A popup will show up. Make sure you accept it.${noColor}"
  xcode-select --install

  # Wait for xcode-select to be installed
  echo
  echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
  echo "Waiting for xcode-select installation to complete..."
  while ! xcode-select -p &>/dev/null; do
    sleep 20
  done
  echo
  echo -e "${boldGreen}xcode-select Installed! Proceeding with Homebrew installation.${noColor}"
else
  echo
  echo -e "${boldGreen}xcode-select is already installed! Proceeding with Homebrew installation.${noColor}"
fi

# Source this in case brew was installed but script needs to re-run
if [ -f ~/.zprofile ]; then
  source ~/.zprofile
fi

# Then go to the main page `https://brew.sh` to find the installation command
if ! command -v brew &>/dev/null; then
  echo
  echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
  echo "Installing brew"
  echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
  # Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo
  echo -e "${boldGreen}Homebrew installed successfully.${noColor}"
else
  echo
  echo -e "${boldGreen}Homebrew is already installed.${noColor}"
fi

# After brew is installed, notice that you need to configure your shell for homebrew
# You can see this in your terminal output in the **Next steps** section
echo
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo "Modifying .zprofile file"
CHECK_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'

# File to be checked and modified
FILE="$HOME/.zprofile"

# Check if the specific line exists in the file
if grep -Fq "$CHECK_LINE" "$FILE"; then
  echo "Content already exists in $FILE"
else
  # Append the content if it does not exist
  echo -e '\n# Configure shell for brew\n'"$CHECK_LINE" >> "$FILE"
  echo "Content added to $FILE"
fi

# After adding it to the .zprofile file, make sure to run the command
source $FILE

echo
echo "########################################################################"
echo "Installing git"
echo "########################################################################"

echo
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
brew install git

echo

# Check if the .ssh directory exists, if not create it
if [ ! -d "$HOME/.ssh" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
fi

echo
echo "########################################################################"
echo "Configuring git..."
echo "########################################################################"

echo
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo "Setting git user.name to $GIT_USER_NAME and email to $GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"
git config --global user.email $GIT_USER_EMAIL

echo
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo "Git access configured, setting up SSH..."


# -----------------------------------------------------------------------------
# SSH SETUP
# -----------------------------------------------------------------------------

# Creates a new SSH key for the new Mac
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo -e "${boldGreen}Generating a new SSH key...${noColor}"
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"

DEFAULT_KEY="${HOME}/.ssh/id_ed25519"
DEFAULT_PUB="${DEFAULT_KEY}.pub"

echo "🔑 SSH Key Setup"
echo "---------------------------------------------"
echo "Do you want to:"
echo "  (n) Generate a NEW SSH key"
echo "  (e) Enter the path to an EXISTING SSH key"
echo "  (s) Skip"
read -p "Choose (n/e/s): " KEY_CHOICE

case "$KEY_CHOICE" in
    n|N)
        echo "Checking if a default SSH key already exists..."

        if [[ -f "$DEFAULT_KEY" && -f "$DEFAULT_PUB" ]]; then
            echo "A default SSH key already exists:"
            echo "$DEFAULT_KEY"
            read -p "Do you still want to create a NEW key? (y/n): " OVERWRITE
            if [[ "$OVERWRITE" != "y" ]]; then
                echo "Aborting new key creation."
                echo "Please re-run and choose 'e' for existing key."
                exit 1
            fi
        fi

        echo "Generating a new SSH key..."
        ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL"

        if [[ ! -f "$DEFAULT_PUB" ]]; then
            echo "⚠️ Could not locate $DEFAULT_PUB."
            echo "If you used a custom filename, enter the PUBLIC key path:"
            read -r DEFAULT_PUB
        fi

        PRIVATE_KEY="${DEFAULT_PUB%.pub}"
        ;;
    
    e|E)
        echo "Please enter the FULL PATH to your *existing private key*:"
        read -r PRIVATE_KEY

        if [[ ! -f "$PRIVATE_KEY" ]]; then
            echo "The file does not exist: $PRIVATE_KEY"
            exit 1
        fi

        DEFAULT_PUB="${PRIVATE_KEY}.pub"
        if [[ ! -f "$DEFAULT_PUB" ]]; then
            echo "Could not find a matching PUBLIC key at $DEFAULT_PUB"
            echo "Please ensure both files exist."
            exit 1
        fi
        ;;

    s|S)
        echo "Skipping SSH setup..."
        ;;

    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "📋 Copying your public key to clipboard..."
pbcopy < "$DEFAULT_PUB"
echo "✅ Public key copied!"

echo "🔎 Checking if ssh-agent is running..."
if [[ -n "$SSH_AUTH_SOCK" && -S "$SSH_AUTH_SOCK" ]]; then
    echo "✅ ssh-agent is already running."
else
    echo "Starting ssh-agent..."
    eval "$(ssh-agent -s)"
fi

echo "🔎 Checking if the private key is already added to ssh-agent..."
KEY_FINGERPRINT="$(ssh-keygen -lf "$PRIVATE_KEY" | awk '{print $2}')"

if ssh-add -l | grep -q "$KEY_FINGERPRINT"; then
    echo "Private key is already loaded in ssh-agent."
else
    echo "Adding private key to ssh-agent..."
    ssh-add "$PRIVATE_KEY"
fi

echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo -e "${boldGreen}Opening GitHub SSH keys page...${noColor}"
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
open "https://github.com/settings/keys"

# Loop until the user confirms
while true; do
    read -p "Have you added your SSH key to GitHub? (y to continue) " CONFIRM
    if [[ "$CONFIRM" == "y" ]]; then
        echo "SSH key setup complete! Continuing..."
        break
    else
        echo "Please add your SSH key to GitHub before continuing."
    fi
done

# -----------------------------------------------------------------------------
# REPOSITORY CLONING
# -----------------------------------------------------------------------------

mkdir -p "$HOME/Documents/repos"

# Function to clone or update repositories
clone_and_update_repo() {
  local repo_name=$1
  local git_repo="git@github.com:jonathanmorris180/$repo_name.git"
  local repo_path="$HOME/Documents/repos/$repo_name"

  echo
  echo "########################################################################"
  echo "Configuring '$repo_name'"
  echo "########################################################################"

  # Check if the directory exists
  if [ -d "$repo_path" ]; then
    if [ -z "$(ls -A "$repo_path")" ]; then
      echo
      echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
      echo "Repository directory exists but is empty. Removing and cloning '$repo_name'..."
      rm -rf "$repo_path"
      git clone "$git_repo" "$repo_path" >/dev/null 2>&1
    elif [ "$(ls -A "$repo_path")" ]; then
      # Directory exists and is not empty, so pull to update the repository
      echo
      echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
      echo "Repository '$repo_name' already exists. Pulling latest changes..."
      cd "$repo_path" && git pull
    fi
  else
    echo
    echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
    echo "Cloning repository '$repo_name'..."
    git clone "$git_repo" "$repo_path" >/dev/null 2>&1
  fi

  if [[ -f ".gitmodules" ]]; then
    echo
    echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
    echo "Submodules detected! Initializing/updating..."
    git submodule update --init --recursive
    echo "Submodules cloned successfully."
  else
    echo "No submodules found."
  fi

  # Verify if the repo was cloned successfully
  if [ ! -d "$repo_path" ]; then
    echo
    echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
    echo -e "${boldRed}Warning: Failed to clone the '$repo_name' repo. Check this manually.${noColor}"
    exit 1
  fi

  echo
  echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
  echo "Successfully configured the '$repo_name' repo."
}

# Clone and update multiple repositories
clone_and_update_repo "dotfiles"
clone_and_update_repo "obsidian"
clone_and_update_repo "forcecode-sf"
clone_and_update_repo "forcecode-web"
clone_and_update_repo "forcecode-cli"
clone_and_update_repo "forcecode-server"
clone_and_update_repo "forcecode-challenges"
clone_and_update_repo "salesforce.nvim"
clone_and_update_repo "resume"
clone_and_update_repo "aoc"
clone_and_update_repo "Adv360-Pro-ZMK"
clone_and_update_repo "apex-fuzzy-finder"
clone_and_update_repo "leetcode.nvim-solutions"

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

echo
echo "########################################################################"
echo "Install brew packages"
echo "########################################################################"

install_if_missing() {
  local type="${@: -1}"    # last argument
  local pkg

  # All arguments except the last one
  local packages=("${@:1:$#-1}")

  for pkg in "${packages[@]}"; do
    echo "Checking for package: $pkg"

    if [[ "$type" == "formula" ]]; then
      if brew list --formula "$pkg" &>/dev/null; then
        echo "$pkg is already installed."
        continue
      fi

      echo "$pkg not found. Installing formula..."
      brew install "$pkg"

    elif [[ "$type" == "cask" ]]; then
      if brew list --cask "$pkg" &>/dev/null; then
        echo "$pkg is already installed."
        continue
      fi

      echo "$pkg not found. Installing cask..."
      brew install --cask "$pkg"
    else
      echo "Unknown type: $type"
      return 1
    fi
  done
}

formulae=(
  btop
  dockutil
  fd
  fzf
  gh
  git-filter-repo
  git-gui
  helm
  postgresql # Don't install specific version - we want psql to be symlinked automatically
  imagemagick
  jq
  ktlint
  awscli
  go
  grpcurl
  neovim
  nvm
  minikube
  basictex
  tree
  pipx
  pnpm
  powerlevel10k
  grpcurl
  prettier
  k9s
  pyenv
  ripgrep
  tldr
  tmux
  tree-sitter-cli
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-vi-mode
  opencode
)

casks=(
  visual-studio-code
  nikitabobko/tap/aerospace
  google-chrome
  cursor
  dbeaver-community
  docker-desktop
  flycut
  font-meslo-lg-nerd-font
  jetbrains-toolbox
  obsidian
  postman
  visual-studio-code
  wezterm
  slack
  whatsapp
)


install_if_missing "${formulae[@]}" formula
install_if_missing "${casks[@]}" cask


echo
echo "########################################################################"
echo "Python"
echo "########################################################################"

pipx install virtualenv 

echo
echo "########################################################################"
echo "Node.js"
echo "########################################################################"

nvm install 24.11.1 # Needed for latest versions of the SF CLI

echo
echo "########################################################################"
echo "Oh My Zsh"
echo "########################################################################"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh not found, installing..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed."
fi

echo
echo "########################################################################"
echo "Salesforce CLI"
echo "########################################################################"

if ! command -v sf &>/dev/null; then
  echo "Installing SF CLI"
  npm install @salesforce/cli --global
fi

echo
echo "########################################################################"
echo "SDKMAN!"
echo "########################################################################"

if ! command -v sdk &>/dev/null; then
  echo "Installing SDKMAN!"
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java 23.0.2-tem
  sdk install maven 3.9.11
fi

echo
echo "########################################################################"
echo "Configure tmux"
echo "########################################################################"

echo
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo "Configuring tmux plugin manager"
if [ ! -d "$HOME/.tmux/plugins/tmp" ]; then
  echo "TPM not found, installing..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
  echo "TPM has already been cloned"
fi

echo "########################################################################"
echo "Source ~/.zshrc file"
echo "########################################################################"

echo
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo "Installing dotfiles..."

bash -c "$HOME/Documents/repos/dotfiles/install.sh"

echo
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo "Sourcing ~/.zshrc file, please wait..."
# Source your zshrc in a new Zsh shell to pull dotfiles-latest
# Run it in a new zsh process as show below or you'll get a lot of errors
zsh -c "source ~/.zshrc"
echo
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo "Sourced ~/.zshrc file"

echo
echo "########################################################################"
echo "Configure macos system settings"
echo "########################################################################"

# NOTE: Most of the settings below were configured on Sequoia 15.6 (24G84)
# (check OS with `system_profiler SPSoftwareDataType`)

# Remove items from dock
KEEP=("System Settings" "Downloads")

is_kept() {
  local item="$1"
  for k in "${KEEP[@]}"; do
    if [[ "$item" == "$k" ]]; then
      return 0
    fi
  done
  return 1
}

# Read dockutil output line by line, splitting on TAB
dockutil --list | while IFS=$'\t' read -r name rest; do
  # Skip empty names (just in case)
  [[ -z "$name" ]] && continue

  if is_kept "$name"; then
    echo "Keeping: $name"
    continue
  fi

  echo "Removing: $name"
  dockutil --remove "$name" --no-restart
done

APPS=(
  "/Applications/DBeaver.app"
  "/Applications/Docker.app"
  "/Applications/WezTerm.app"
  "/Applications/Slack.app"
  "/Applications/Google Chrome.app"
  "/Applications/Obsidian.app"
  "/Applications/Postman.app"
  "/Applications/WhatsApp.app"
)

for app in "${APPS[@]}"; do
  if [[ -d "$app" ]]; then
    echo "Adding: $app"
    dockutil --add "$app" --no-restart
  else
    echo "Skipping (not found): $app" >&2
  fi
done

# Configure apps that start after booting up (login items)
# https://apple.stackexchange.com/questions/310495/can-login-items-be-added-via-the-command-line-in-high-sierra
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Flycut.app", hidden:false}'
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/AeroSpace.app", hidden:false}'
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/JetBrains Toolbox.app", hidden:false}'

# TO PREVENT MAC FROM REOPENING APPS AFTER A REBOOT
# MacOS stores the current session info in a file while your logged on and
# stores info on what Apps are currently open, window size and position.
# By disabling system access to this file we can permanently stop MacOS from
# re-opening apps after rebooting
# https://www.tonymacx86.com/threads/guide-permanently-disable-macos-from-re-opening-apps-on-restart-boot.296200/
#
# flag the file as owned by root (otherwise MacOS will replace it)
# sudo chown root ~/Library/Preferences/ByHost/com.apple.loginwindow.*
# remove all permissions (so that it can not be read or written to)
# sudo chmod 000 ~/Library/Preferences/ByHost/com.apple.loginwindow.*
#
# If you need to re-enable the feature you can simply delete the existing file
# sudo rm -f ~/Library/Preferences/ByHost/com.apple.loginwindow.*

# SYSTEM SETTINGS
# https://macos-defaults.com
#
# HACK: How to view stuff that changes after you change them manually in system
# settings
# Before making the change
# defaults read > ~/macos-before-change.txt
# Then go and make the change in system settings
# defaults read > ~/macos-after-change.txt
# Then open Neovim on the first file and run :vert diffs <second-file>
# NOTE: There are some settings, like the trackpad ones that only work on the
# laptop with a trackpad

# Through GUI KeyRepeat rate min is 2 (30 ms)
# Through GUI InitialKeyRepeat rate min is 15 (225 ms)
# To see what the CURRENT VALUE for each the **Key repeat rate** and the **Delay until repeat** are
# defaults read -g KeyRepeat
# defaults read -g InitialKeyRepeat
defaults write -g KeyRepeat -int 2 # Can be set lower, but then I tend to have issues with accidental repeats
defaults write -g InitialKeyRepeat -int 15

# Set mouse to secondary click on the right side
# To get CURRENT VALUE
# This doesn't seem to work for some reason even though the value seems to update correctly via the CLI (no idea why)
# Below are two different places it needs to be set
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string "TwoButton"
defaults write com.apple.driver.AppleBluetoothMultitouch.MouseButtonMode -string "TwoButton"

# Allows swipe left or right (navigate forwards and back in Chrome with a finger)
defaults write "Apple Global Domain" AppleEnableMouseSwipeNavigateWithScrolls -bool true

# Show item info below desktop icons
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

# Enable snap-to-grid for desktop icons
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Empty Trash securely by default
defaults write com.apple.finder EmptyTrashSecurely -bool true

# Show the ~/Library folder
chflags nohidden ~/Library

# Mouse cursor speed
# Max value via system settings is 3, but notice I set it to 4 via the command
# To get CURRENT VALUE
# defaults read NSGlobalDomain com.apple.mouse.scaling
defaults write NSGlobalDomain com.apple.mouse.scaling -float "1.5"

# Enable Reduce Motion
# To get CURRENT VALUE
# defaults read com.apple.universalaccess reduceMotion
defaults write com.apple.universalaccess reduceMotion -bool true
defaults write com.apple.Accessibility ReduceMotionEnabled -bool true

############################################

# Automatically hide the dock
defaults write com.apple.dock autohide -bool true

# Group applications together (helps to find applications with swipe up since Mac doesn't seem to like Aerospace groupings)
defaults write com.apple.WindowManager AppWindowGroupingBehavior -bool "true"

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable Show Recent Applications in Dock
# To get CURRENT VALUE
# defaults read com.apple.dock show-recents
defaults write com.apple.dock show-recents -bool false

# Restart the Dock to apply changes
# If you have 'System Settings' open and don't see the changes, close
# 'System Settings' and open it again
killall Dock

############################################

# Show path bar
# defaults read com.apple.finder "ShowPathbar"
defaults write com.apple.finder "ShowPathbar" -bool "true"

killall Finder

echo
echo -e "${boldPurple}>>>>>>>>>>>>>>>>>>>>>>>>>>${noColor}"
echo -e "${boldYellow}NOTE: Some changes, like 'KeyRepeat', require a reboot${noColor}"

echo
echo "########################################################################"
echo "Open installed apps"
echo "########################################################################"

open -a 'WezTerm'
open -a 'Aerospace'

echo -e "${boldGreen}
Installation complete! Restart the computer now to ensure all settings have been applied.

Manual steps to check:
- Set up SSH for DigitalOcean and Dokku by copying from another device to ~/.ssh/config (can use AirDrop)
- Start up Aerospace again if you had to grant permissions (it doesn't automatically open after they are granted)
- Install tmux plugins with prefix + I (capital i)
- Install IntelliJ with JetBrains Toolbox (there seems to be a CLI that could be used for this, but I can't find the JAR anywhere: https://www.jetbrains.com/help/toolbox-app/toolbox-app-cli.html)
- Set up right-click with mouse (the command above doesn't seem to work for some reason)
- Add .env files from password manager
- Go through README to set up Forcecode development
- Import ORGanizer extension backup (you'll need to export from other laptop and share via AirDrop)
- Allow notifications for Slack

${noColor}
"
