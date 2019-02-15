#!/usr/bin/env bash

# Install some stuff before others!
important_casks=(
  google-chrome
  jetbrains-toolbox
  java8
)

brews=(
  libyaml
  ansible
  awscli
  kubernetes-cli
  go
  gpg
  iftop
  wget
  telnet
  nmap
  node
  pgcli
  python
  python3
  tree
  maven
  gradle
)

casks=(
  adobe-acrobat
  android-studio
  android-platform-tools
  docker
  docker-toolbox
  google-backup-and-sync
  microsoft-office
  skype
  slack
  sublime-text
  sourcetree
  vlc
  postman
  virtualbox
  the-unarchiver
  pgadmin4
  viscosity
  android-file-transfer
)

gpg_key='C84B1718'

git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "credential.helper osxkeychain"
  "user.name Gerald Madlmayr"
  "user.email gerald.madlmayr@gmx.at"
  "user.signingkey ${gpg_key}"
)


######################################## End of app list ########################################
set +e
set -x

# show hidden files in finder. (This requires a Reboot to take effect)
defaults write com.apple.finder AppleShowAllFiles TRUE

# Enable tap to click (Trackpad)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    prompt "Execute: $exec"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
      if [[ ! -z "${CI}" ]]; then
        exit 1
      fi
    fi
  done
}

function brew_install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then 
      echo "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      echo "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  prompt "Install Xcode (select 'install' only, as we don't need the full xcode)"
  xcode-select --install

  prompt "Install Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  if [[ -z "${CI}" ]]; then
    prompt "Update Homebrew"
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Install important software ..."
brew tap caskroom/versions
install 'brew cask install' "${important_casks[@]}"

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

prompt "Install SSH Pass to enable Ansible pass an SSH Key when logging in"
brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb

prompt "Set git defaults"
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

prompt "Install software"
install 'brew cask install' "${casks[@]}"

if [[ -z "${CI}" ]]; then
  prompt "Install software from App Store"
  mas list
fi

# https://github.com/keybase/keybase-issues/issues/2798
export GPG_TTY=$(tty)

prompt "Cleanup"
brew cleanup
brew cask cleanup

echo "Done!"
