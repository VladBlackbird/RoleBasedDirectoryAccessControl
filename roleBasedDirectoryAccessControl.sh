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
      sudo mkdir -p "$dir"
    done
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
    sudo chown :"$role" "$dir"
    sudo chmod 770 "$dir"
  done
done

