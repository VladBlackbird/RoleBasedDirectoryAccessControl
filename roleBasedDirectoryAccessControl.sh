#!/bin/bash

# Check if the user has root privileges
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or use sudo to execute this script." | tee -a $LOGFILE
  exit
fi

LOGFILE="/var/log/my_script.log"

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "This script manages roles, directories, and permissions."
  echo
  echo "Options:"
  echo "  --help, -h    Show this help message and exit"
  echo
  echo "Examples:"
  echo "  $0"
  exit 1
}

for i in "$@"; do
  case $i in
    -h|--help)
      usage
      shift
      ;;
    *)
      # unknown option
      ;;
  esac
done

# Function to check if the entered permissions are valid
function isValidPermission() {
  if [[ $1 =~ ^[0-7]{3}$ ]]; then
    return 0
  else
    return 1
  fi
}

# Function to check if the user exists
function userExists() {
  if id -u "$1" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Function to check if the entered permissions are valid
function isValidPermission() {
  if [[ $1 =~ ^[0-7]{3}$ ]]; then
    return 0
  else
    return 1
  fi
}

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
    if isValidPermission "${perms[$index]}"; then
      dir_perms["${dirs[$index]}"]="${perms[$index]}"
    else
      echo "Invalid permission ${perms[$index]} for directory ${dirs[$index]}." | tee -a $LOGFILE
      exit 1
    fi
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

# Function to check if a directory is empty
function isDirEmpty() {
  if [ -d "$1" ]; then
    if [ "$(ls -A $1)" ]; then
      return 1
    else
      return 0
    fi
  else
    return 1
  fi
}

# Ask user if they want to delete any directories
echo "Do you want to delete any directories? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter directories to delete, separated by space:" | tee -a $LOGFILE
  read -ra dirs
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      if isDirEmpty "$dir"; then
        sudo rm -r "$dir" | tee -a $LOGFILE
      else
        echo "Directory $dir is not empty. Please remove the files before deleting the directory." | tee -a $LOGFILE
      fi
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
    else
      echo "Directory $dir does not exist." | tee -a $LOGFILE
    fi
  done
done

# Function to check if a directory is writable by a user
function isDirWritable() {
  if [ -w "$1" ]; then
    return 0
  else
    return 1
  fi
}

# Check if the directory exists before changing permissions
echo "Do you want to modify permissions of any directories? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter directories to modify permissions, separated by space:" | tee -a $LOGFILE
  read -ra dirs
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      if isDirWritable "$dir"; then
        echo "Enter new permissions for $dir (e.g. 770):" | tee -a $LOGFILE
        read -r perms
        sudo chmod "$perms" "$dir" | tee -a $LOGFILE
      else
        echo "Directory $dir is not writable." | tee -a $LOGFILE
      fi
    else
      echo "Directory $dir does not exist." | tee -a $LOGFILE
    fi
  done
fi

# Check if the directory exists before changing ownership
echo "Do you want to change ownership of any directories? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter directories to change ownership, separated by space:" | tee -a $LOGFILE
  read -ra dirs
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      echo "Enter new owner for $dir:" | tee -a $LOGFILE
      read -r owner
      if userExists "$owner"; then
        sudo chown "$owner" "$dir" | tee -a $LOGFILE
      else
        echo "User $owner does not exist." | tee -a $LOGFILE
      fi
    else
      echo "Directory $dir does not exist." | tee -a $LOGFILE
    fi
  done
fi

# Ask user if they want to change group of any directories
echo "Do you want to change group of any directories? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter directories to change group, separated by space:" | tee -a $LOGFILE
  read -ra dirs
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      echo "Enter new group for $dir:" | tee -a $LOGFILE
      read -r group
      if groupExists "$group"; then
        sudo chgrp "$group" "$dir" | tee -a $LOGFILE
      else
        echo "Group $group does not exist." | tee -a $LOGFILE
      fi
    else
      echo "Directory $dir does not exist." | tee -a $LOGFILE
    fi
  done
fi

# Add feature to allow the user to add users to the groups
# Add feature to check if the group exists before adding a user to it
function groupExists() {
  if getent group "$1" > /dev/null; then
    return 0
  else
    return 1
  fi
}

# Modify the section where users are added to the groups
echo "Do you want to add users to the groups? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  for role in "${roles[@]}"; do
    if groupExists "$role"; then
      echo "Enter users to add to the $role group, separated by space:" | tee -a $LOGFILE
      read -ra users
      for user in "${users[@]}"; do
        if userExists "$user"; then
          sudo usermod -a -G "$role" "$user" | tee -a $LOGFILE
        else
          echo "User $user does not exist." | tee -a $LOGFILE
        fi
      done
    else
      echo "Group $role does not exist." | tee -a $LOGFILE
    fi
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
      if userExists "$user"; then
        sudo gpasswd -d "$user" "$role" | tee -a $LOGFILE
      else
        echo "User $user does not exist." | tee -a $LOGFILE
      fi
    done
  done
fi

# Ask user if they want to delete any users
echo "Do you want to delete any users? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter users to delete, separated by space:" | tee -a $LOGFILE
  read -ra users
  for user in "${users[@]}"; do
    if userExists "$user"; then
      sudo userdel "$user" | tee -a $LOGFILE
    else
      echo "User $user does not exist." | tee -a $LOGFILE
    fi
  done
fi

# Add feature to create new users and add them to the groups
echo "Do you want to create new users and add them to the groups? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  for role in "${roles[@]}"; do
    if groupExists "$role"; then
      echo "Enter new users to create and add to the $role group, separated by space:" | tee -a $LOGFILE
      read -ra users
      for user in "${users[@]}"; do
        if ! userExists "$user"; then
          sudo useradd "$user" | tee -a $LOGFILE
          sudo usermod -a -G "$role" "$user" | tee -a $LOGFILE
        else
          echo "User $user already exists." | tee -a $LOGFILE
        fi
      done
    else
      echo "Group $role does not exist." | tee -a $LOGFILE
    fi
  done
fi

# Ask user if they want to change password of any users
echo "Do you want to change password of any users? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter users to change password, separated by space:" | tee -a $LOGFILE
  read -ra users
  for user in "${users[@]}"; do
    if userExists "$user"; then
      echo "Enter new password for $user:" | tee -a $LOGFILE
      read -s password
      echo "$password" | sudo passwd --stdin "$user" | tee -a $LOGFILE
    else
      echo "User $user does not exist." | tee -a $LOGFILE
    fi
  done
fi

# Ask user if they want to change shell of any users
echo "Do you want to change shell of any users? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter users to change shell, separated by space:" | tee -a $LOGFILE
  read -ra users
  for user in "${users[@]}"; do
    if userExists "$user"; then
      echo "Enter new shell for $user (e.g. /bin/bash):" | tee -a $LOGFILE
      read -r shell
      if [ -x "$shell" ]; then
        sudo chsh -s "$shell" "$user" | tee -a $LOGFILE
      else
        echo "Shell $shell does not exist or is not executable." | tee -a $LOGFILE
      fi
    else
      echo "User $user does not exist." | tee -a $LOGFILE
    fi
  done
fi

# Add feature to list all users in a group
echo "Do you want to list all users in a group? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the group name:" | tee -a $LOGFILE
  read -r group
  if groupExists "$group"; then
    echo "Users in the $group group:" | tee -a $LOGFILE
    grep "^$group:" /etc/group | cut -d: -f4 | tee -a $LOGFILE
  else
    echo "Group $group does not exist." | tee -a $LOGFILE
  fi
fi

# Function to check if a user is in a specific group
function isUserInGroup() {
  if id -nG "$1" | grep -qw "$2"; then
    return 0
  else
    return 1
  fi
}

# Ask user if they want to check if a user is in a specific group
echo "Do you want to check if a user is in a specific group? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the username:" | tee -a $LOGFILE
  read -r user
  echo "Enter the group name:" | tee -a $LOGFILE
  read -r group
  if userExists "$user"; then
    if groupExists "$group"; then
      if isUserInGroup "$user" "$group"; then
        echo "User $user is in the $group group." | tee -a $LOGFILE
      else
        echo "User $user is not in the $group group." | tee -a $LOGFILE
      fi
    else
      echo "Group $group does not exist." | tee -a $LOGFILE
    fi
  else
    echo "User $user does not exist." | tee -a $LOGFILE
  fi
fi

# Function to check if a user is locked
function isUserLocked() {
  if sudo passwd -S "$1" | grep -q "L"; then
    return 0
  else
    return 1
  fi
}

# Ask user if they want to check if a user is locked
echo "Do you want to check if a user is locked? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the username:" | tee -a $LOGFILE
  read -r user
  if userExists "$user"; then
    if isUserLocked "$user"; then
      echo "User $user is locked." | tee -a $LOGFILE
    else
      echo "User $user is not locked." | tee -a $LOGFILE
    fi
  else
    echo "User $user does not exist." | tee -a $LOGFILE
  fi
fi

# Function to check if a user's password is about to expire or has already expired
function isPasswordExpiring() {
  local expiry_date=$(sudo chage -l "$1" | grep "Password expires" | cut -d: -f2)
  if [[ "$expiry_date" == " never" ]]; then
    echo "Password for user $1 never expires." | tee -a $LOGFILE
  elif [[ "$expiry_date" < $(date +"%b %d, %Y") ]]; then
    echo "Password for user $1 has already expired." | tee -a $LOGFILE
  else
    echo "Password for user $1 expires on $expiry_date." | tee -a $LOGFILE
  fi
}

# Ask user if they want to check if a user's password is about to expire or has already expired
echo "Do you want to check if a user's password is about to expire or has already expired? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the username:" | tee -a $LOGFILE
  read -r user
  if userExists "$user"; then
    isPasswordExpiring "$user"
  else
    echo "User $user does not exist." | tee -a $LOGFILE
  fi
fi

# Function to list all groups a user belongs to
function listUserGroups() {
  if id -u "$1" > /dev/null 2>&1; then
    echo "Groups for user $1:" | tee -a $LOGFILE
    id -nG "$1" | tee -a $LOGFILE
  else
    echo "User $1 does not exist." | tee -a $LOGFILE
  fi
}

# Ask user if they want to list all groups a user belongs to
echo "Do you want to list all groups a user belongs to? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the username:" | tee -a $LOGFILE
  read -r user
  listUserGroups "$user"
fi

# Function to list all users in the system
function listAllUsers() {
  echo "All users in the system:" | tee -a $LOGFILE
  cut -d: -f1 /etc/passwd | tee -a $LOGFILE
}

# Ask user if they want to list all users in the system
echo "Do you want to list all users in the system? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  listAllUsers
fi

# Function to list all groups in the system
function listAllGroups() {
  echo "All groups in the system:" | tee -a $LOGFILE
  cut -d: -f1 /etc/group | tee -a $LOGFILE
}

# Ask user if they want to list all groups in the system
echo "Do you want to list all groups in the system? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  listAllGroups
fi

# Function to check if a user's account is active
function isUserActive() {
  local expiry_date=$(sudo chage -l "$1" | grep "Account expires" | cut -d: -f2)
  if [[ "$expiry_date" == " never" ]]; then
    echo "Account for user $1 never expires." | tee -a $LOGFILE
  elif [[ "$expiry_date" < $(date +"%b %d, %Y") ]]; then
    echo "Account for user $1 has already expired." | tee -a $LOGFILE
  else
    echo "Account for user $1 expires on $expiry_date." | tee -a $LOGFILE
  fi
}

# Ask user if they want to check if a user's account is active
echo "Do you want to check if a user's account is active? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the username:" | tee -a $LOGFILE
  read -r user
  if userExists "$user"; then
    isUserActive "$user"
  else
    echo "User $user does not exist." | tee -a $LOGFILE
  fi
fi
# Function to check if a user's home directory exists and is accessible
function isUserHomeAccessible() {
  local home_dir=$(getent passwd "$1" | cut -d: -f6)
  if [ -d "$home_dir" ]; then
    if [ -r "$home_dir" ]; then
      echo "Home directory for user $1 exists and is readable." | tee -a $LOGFILE
    else
      echo "Home directory for user $1 exists but is not readable." | tee -a $LOGFILE
    fi
  else
    echo "Home directory for user $1 does not exist." | tee -a $LOGFILE
  fi
}

# Ask user if they want to check if a user's home directory exists and is accessible
echo "Do you want to check if a user's home directory exists and is accessible? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the username:" | tee -a $LOGFILE
  read -r user
  if userExists "$user"; then
    isUserHomeAccessible "$user"
  else
    echo "User $user does not exist." | tee -a $LOGFILE
  fi
fi

# Function to check if a user's shell is valid
function isUserShellValid() {
  local user_shell=$(getent passwd "$1" | cut -d: -f7)
  if grep -Fxq "$user_shell" /etc/shells; then
    echo "Shell for user $1 is valid." | tee -a $LOGFILE
  else
    echo "Shell for user $1 is not valid." | tee -a $LOGFILE
  fi
}

# Ask user if they want to check if a user's shell is valid
echo "Do you want to check if a user's shell is valid? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the username:" | tee -a $LOGFILE
  read -r user
  if userExists "$user"; then
    isUserShellValid "$user"
  else
    echo "User $user does not exist." | tee -a $LOGFILE
  fi
fi

# Function to check if a user's password is locked
function isUserPasswordLocked() {
  local status=$(sudo passwd -S "$1" | awk '{print $2}')
  if [[ "$status" == "L" ]]; then
    echo "Password for user $1 is locked." | tee -a $LOGFILE
  else
    echo "Password for user $1 is not locked." | tee -a $LOGFILE
  fi
}

# Ask user if they want to check if a user's password is locked
echo "Do you want to check if a user's password is locked? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the username:" | tee -a $LOGFILE
  read -r user
  if userExists "$user"; then
    isUserPasswordLocked "$user"
  else
    echo "User $user does not exist." | tee -a $LOGFILE
  fi
fi

# Function to lock a user account
function lockUserAccount() {
  sudo passwd -l "$1" | tee -a $LOGFILE
}

# Function to unlock a user account
function unlockUserAccount() {
  sudo passwd -u "$1" | tee -a $LOGFILE
}

# Ask user if they want to lock or unlock any user accounts
echo "Do you want to lock or unlock any user accounts? (y/n)" | tee -a $LOGFILE
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]] ;then
  echo "Enter the usernames, separated by space:" | tee -a $LOGFILE
  read -ra users
  echo "Do you want to lock or unlock these user accounts? (lock/unlock)" | tee -a $LOGFILE
  read -r action
  for user in "${users[@]}"; do
    if userExists "$user"; then
      if [[ "$action" == "lock" ]]; then
        lockUserAccount "$user"
      elif [[ "$action" == "unlock" ]]; then
        unlockUserAccount "$user"
      else
        echo "Invalid action. Please enter 'lock' or 'unlock'." | tee -a $LOGFILE
      fi
    else
      echo "User $user does not exist." | tee -a $LOGFILE
    fi
  done
fi
