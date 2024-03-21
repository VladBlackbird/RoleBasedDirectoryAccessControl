#!/bin/bash

# Check if the user has root privileges
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or use sudo to execute this script." | tee -a $LOGFILE
  exit
fi

LOGFILE="/var/log/my_script.log"

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ask user for roles
echo "Enter roles, separated by space:" | tee -a $LOGFILE
read -ra roles

# Ask user for directories and their permissions for each role
declare -A role_dirs
declare -A dir_perms
for role in "${roles[@]}"; do
  echo "Enter directories for $role, separated by space:" | tee -a $LOGFILE
  read -ra dirs
  role_dirs["$role"]="${dirs[@]}"
  echo "Enter permissions for each directory (in the same order), separated by space:" | tee -a $LOGFILE
  read -ra perms
  for index in "${!dirs[@]}"; do
    dir_perms["${dirs[$index]}"]="${perms[$index]}"
  done
done

# Ask user if they want to create the directories
echo "Do you want to create these directories? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  for role in "${!role_dirs[@]}"; do
    IFS=' ' read -ra dirs <<< "${role_dirs[$role]}"
    for dir in "${dirs[@]}"; do
      if [ ! -d "$dir" ]; then
        sudo mkdir -p "$dir" | tee -a $LOGFILE
      else
        echo "Directory $dir already exists." | tee -a $LOGFILE
      fi
    done
  done
fi

# Ask user if they want to delete any directories
echo "Do you want to delete any directories? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter directories to delete, separated by space:" | tee -a $LOGFILE
  read -ra dirs
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      sudo rm -r "$dir" | tee -a $LOGFILE
    else
      echo "Directory $dir does not exist." | tee -a $LOGFILE
    fi
  done
fi

# Create groups for each role
for role in "${roles[@]}"; do
  if ! getent group "$role" > /dev/null; then
    sudo groupadd "$role" | tee -a $LOGFILE
  fi
done

# Set directory permissions for each role
for role in "${!role_dirs[@]}"; do
  IFS=' ' read -ra dirs <<< "${role_dirs[$role]}"
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      sudo chown :"$role" "$dir" | tee -a $LOGFILE
      sudo chmod "${dir_perms[$dir]}" "$dir" | tee -a $LOGFILE
    fi
  done
done

# Ask user if they want to modify permissions of any directories
echo "Do you want to modify permissions of any directories? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter directories to modify permissions, separated by space:" | tee -a $LOGFILE
  read -ra dirs
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      echo "Enter new permissions for $dir (e.g. 770):" | tee -a $LOGFILE
      read -r perms
      sudo chmod "$perms" "$dir" | tee -a $LOGFILE
    else
      echo "Directory $dir does not exist." | tee -a $LOGFILE
    fi
  done
fi

# Add feature to allow the user to add users to the groups
# Ask user if they want to add users to the groups
echo "Do you want to add users to the groups? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  for role in "${roles[@]}"; do
    echo "Enter users to add to the $role group, separated by space:" | tee -a $LOGFILE
    read -ra users
    for user in "${users[@]}"; do
      if id -u "$user" >/dev/null 2>&1; then
        sudo usermod -a -G "$role" "$user" | tee -a $LOGFILE
      else
        echo "User $user does not exist." | tee -a $LOGFILE
      fi
    done
  done
fi

# Remove users from the groups
echo "Do you want to remove users from the groups? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  for role in "${roles[@]}"; do
    echo "Enter users to remove from the $role group, separated by space:" | tee -a $LOGFILE
    read -ra users
    for user in "${users[@]}"; do
      if id -u "$user" >/dev/null 2>&1; then
        sudo gpasswd -d "$user" "$role" | tee -a $LOGFILE
      else
        echo "User $user does not exist." | tee -a $LOGFILE
      fi
    done
  done
fi
