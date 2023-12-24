#!/bin/bash
# *******************************************************************************
# - Script to generate an SSH key for connection and, a GPG key for security.
# - Upgrades Termux packages and, installs vim, git, openssh, gnupg,etc. packages.
# - Generates an SSH key as well as a GPG key for adding them to GitHub's account.
# - Author: Díwash Neupane (Diwash0007)
# - Version: generic:1.3
# - Date: 20231225
#
#        - Changes for (20230802)  - make it clear that this script is not ready.
#        - Changes for (20230803)  - make it clear that this script is ready.
#        - Changes for (20231020)  - generate an SSH key and, a GPG key by following official method guided by GitHub.
#        - Changes for (20231020)  - support for creating and, restoring backup.
#        - Changes for (20231224)  - support to restore gnupg files even if termux is fresh.
#        - Changes for (20231225)  - separately back up and restore ssh and gpg keys.
#
# *******************************************************************************

# required variables
check_inputs() {
  echo "-- Note: enter you valid GitHub username and email only or else script might fail!";
  echo "-- Enter your username:";
  read username;
  echo "-- Enter your email address:";
  read user_email;

  # extra packages
  echo "-- Do you want to install any other packages (Y/n)?";
  read input;
  if [ "$input" = 'y' ] || [ "$input" = 'Y' ]; then
      echo "-- Enter name of the package you want to install:";
      read package_name;
      extra_packages="vim $package_name";
  else
      extra_packages="vim";
  fi
}

# update Termux's environment
update_environment() {
  pkg update && pkg upgrade;
}

# install required packages
install_packages() {
  echo "-----------------------------------";
  echo "-- Installing required packages ...";
  echo "-----------------------------------";
  pkg install git openssh gnupg $extra_packages;
  echo "-- Required packages has been installed.";
}

# generate an SSH key
generate_an_ssh_key() {
  echo "---------------------------------------";
  echo "-- Generating an SSH key for GitHub ...";
  echo "---------------------------------------";
  ssh-keygen -t rsa -b 4096 -C "$user_email";
  eval "$(ssh-agent -s)";
  ssh-add ~/.ssh/id_rsa;
  echo "-- SSH key has been generated and, added to ssh-agent.";
}

# generate a GPG key
generate_a_gpg_key() {
  echo "--------------------------------------";
  echo "-- Generating a GPG key for GitHub ...";
  echo "--------------------------------------";
  gpg --full-generate-key;
  gpg --list-secret-keys --keyid-format=long;
  echo "-- Enter GPG key ID:";
  read gpg_key_id;
  gpg --armor --export $gpg_key_id > ~/.gnupg/id_gpg;
  # configure git for signing key
  git config --global commit.gpgsign true;
  git config --global user.signingkey $gpg_key_id;
  echo "-- GPG key has been generated and, exported.";
}

# configure git for an SSH key and, a GPG key
config_git_and_gpg_key() {
  echo "---------------------------------------";
  echo "-- Configuring git for your GPG key ...";
  echo "---------------------------------------";
  git config --global user.email "$user_email";
  git config --global user.name "$username";
  # add GPG key to your `.bashrc` startup file
  [ -f ~/.bashrc ] || touch ~/.bashrc && echo -e '# Set `GPG_TTY` for GPG (GNU Privacy Guard) passphrase handling\nexport GPG_TTY=$(tty)' >> ~/.bashrc;
  source ~/.bashrc;
  echo "-- Git configuration completed. Additionally, GPG_TTY has been configured for seamless usage of GPG keys.";
}

# show an SSH and a GPG public keys for adding them to GitHub account
show_ssh_and_gpg_public_keys() {
  echo "------------------------------------------";
  echo "-- Your SSH public key is displayed below:";
  echo "------------------------------------------";
  cat ~/.ssh/id_rsa.pub;
  echo "";
  echo "------------------------------------------";
  echo "-- Your GPG public key is displayed below:";
  echo "------------------------------------------";
  cat ~/.gnupg/id_gpg;
  # cleanup junk
  rm ~/.gnupg/id_gpg;
}

# backup GPG key
backup_gpg_key() {
  echo "------------------------";
  echo "-- Backing up GPG key...";
  echo "------------------------";
  gpg --export --export-options backup --output ~/id_gpg_public $user_email;
  gpg --export-secret-keys --export-options backup --output ~/id_gpg_private;
  gpg --export-ownertrust > ~/gpg_ownertrust;
  cat ~/gpg_ownertrust;
  ls -a;
  echo "-- Back up completed.";
}

# backup SSH key
backup_ssh_key() {
  echo "------------------------";
  echo "-- Backing up SSH key...";
  echo "------------------------";
  if [ -f $HOME/.ssh/id_rsa ] && [ -f $HOME/.ssh/id_rsa.pub ]; then
      cp $HOME/.ssh/id_rsa $HOME/.ssh/id_rsa.pub $HOME;
      echo "-- SSH key backed up.";
  else
      echo "-- No existing SSH key found.";
  fi
  ls -a;
  echo "-- Back up completed.";
}

# restore GPG key
restore_gpg_key() {
  echo "--------------------";
  echo "-- Restoring GPG key";
  echo "--------------------";
  pkg update;
  # when GNU Privacy Guard (gnupg) is not installed
  if dpkg -s gnupg >/dev/null 2>&1; then
    echo "--GNU Privacy Guard (gnupg) is installed.";
  else
    echo "--GNU Privacy Guard (gnupg) is not installed.";
    echo "-- Installing GNU Privacy Guard (gnupg)...";
    pkg install gnupg;
  fi
  gpg --import ~/id_gpg_public;
  gpg --import ~/id_gpg_private;
  gpg --import ~/gpg_ownertrust;
  gpg --list-secret-keys --keyid-format=long;
  echo "-- Enter GPG key ID:";
  read gpg_key_id;
  # configure git for signing key
  git config --global commit.gpgsign true;
  git config --global user.signingkey $gpg_key_id;
  echo "-- Restored.";
}

# restore SSH key
restore_ssh_key() {
  echo "--------------------";
  echo "-- Restoring SSH key";
  echo "--------------------";
  if [ -f $HOME/id_rsa ] && [ -f $HOME/id_rsa.pub ]; then
      mv $HOME/id_rsa $HOME/id_rsa.pub $HOME/.ssh;
      echo "-- SSH key restored.";
      eval "$(ssh-agent -s)";
      ssh-add ~/.ssh/id_rsa;
  else
      echo "-- No SSH key backup found.";
  fi
  echo "-- Restored.";
}

# do all the work!
WorkNow() {
    local SCRIPT_VERSION="20230803";
    local START=$(date);
    local STOP=$(date);
    echo "$0, v$SCRIPT_VERSION";
    check_inputs;
    echo "-- Do you want to back up ssh or gpg keys (bs/bg) or restore ssh or gpg keys (rs/rg) or start fresh setup only (s) or fresh setup plus generate ssh and gpg keys (ssg) ?";
    read answer;
    case "$answer" in
        "bs")
            backup_ssh_key;
            ;;
        "bg")
            backup_gpg_key;
            ;;
        "rs")
            restore_ssh_key;
            ;;
        "rg")
            restore_gpg_key;
            config_git_and_gpg_key;
            ;;
        "s")
            update_environment;
            install_packages;
            ;;
      "ssg")
            update_environment;
            install_packages;
            generate_an_ssh_key;
            generate_a_gpg_key;
            config_git_and_gpg_key;
            show_ssh_and_gpg_public_keys;
            echo "-- Now, you can copy your SSH as well as GPG public keys and, add them to your GitHub's account.";
            ;;
          *)
            echo "-- Start time = $START";
            echo "-- Stop time = $STOP";
            exit 0;
            ;;
    esac
}

# --- main() ---
WorkNow;
# --- end main() ---