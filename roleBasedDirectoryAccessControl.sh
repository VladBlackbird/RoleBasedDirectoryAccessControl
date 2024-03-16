#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ask user for roles
echo "Enter roles, separated by space:"
read -ra roles

# Ask user for directories for each role
declare -A role_dirs
for role in "${roles[@]}"; do
  echo "Enter directories for $role, separated by space:"
  read -ra dirs
  role_dirs["$role"]="${dirs[@]}"
done

# Ask user if they want to create the directories
echo "Do you want to create these directories? (y/n)"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  for role in "${!role_dirs[@]}"; do
    IFS=' ' read -ra dirs <<< "${role_dirs[$role]}"
    for dir in "${dirs[@]}"; do
      if [ ! -d "$dir" ]; then
        sudo mkdir -p "$dir"
      else
        echo "Directory $dir already exists."
      fi
    done
  done
fi

# Ask user if they want to delete any directories
echo "Do you want to delete any directories? (y/n)"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter directories to delete, separated by space:"
  read -ra dirs
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      sudo rm -r "$dir"
    else
      echo "Directory $dir does not exist."
    fi
  done
fi

# Create groups for each role
for role in "${roles[@]}"; do
  if ! getent group "$role" > /dev/null; then
    sudo groupadd "$role"
  fi
done

# Set directory permissions for each role
for role in "${!role_dirs[@]}"; do
  IFS=' ' read -ra dirs <<< "${role_dirs[$role]}"
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      sudo chown :"$role" "$dir"
      sudo chmod 770 "$dir"
    fi
  done
done

# Ask user if they want to modify permissions of any directories
echo "Do you want to modify permissions of any directories? (y/n)"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter directories to modify permissions, separated by space:"
  read -ra dirs
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      echo "Enter new permissions for $dir (e.g. 770):"
      read -r perms
      sudo chmod "$perms" "$dir"
    else
      echo "Directory $dir does not exist."
    fi
  done
fi

# Add feature to allow the user to add users to the groups
# Ask user if they want to add users to the groups
echo "Do you want to add users to the groups? (y/n)"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  for role in "${roles[@]}"; do
    echo "Enter users to add to the $role group, separated by space:"
    read -ra users
    for user in "${users[@]}"; do
      if id -u "$user" >/dev/null 2>&1; then
        sudo usermod -a -G "$role" "$user"
      else
        echo "User $user does not exist."
      fi
    done
  done
fi
