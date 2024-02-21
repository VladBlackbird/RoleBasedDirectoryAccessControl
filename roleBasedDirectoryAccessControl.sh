#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ask user for roles
echo "Enter roles, separated by space:"
read -a roles

# Ask user for directories for each role
declare -A role_dirs
for role in "${roles[@]}"; do
  echo "Enter directories for $role, separated by space:"
  read -a dirs
  role_dirs[$role]=${dirs[@]}
done

# Ask user if they want to create the directories
echo "Do you want to create these directories? (y/n)"
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  for role in "${!role_dirs[@]}"; do
    for dir in ${role_dirs[$role]}; do
      sudo mkdir -p $dir
    done
  done
fi

# Create groups for each role
for role in "${roles[@]}"; do
  sudo groupadd $role
done

# Set directory permissions for each role
for role in "${!role_dirs[@]}"; do
  for dir in ${role_dirs[$role]}; do
    sudo chown :$role $dir
    sudo chmod 770 $dir
  done
done
