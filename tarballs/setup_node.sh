#!/bin/bash

# Define log files
LOG_FILE="/tmp/install_log.txt"
ERROR_FILE="/tmp/install_error_log.txt"

# Ensure log files are empty at the start
: > "$LOG_FILE"
: > "$ERROR_FILE"

# Define a function to log and execute commands
log_and_run() {
    echo "Executing: $*" | tee -a "$LOG_FILE" # Log command being executed
    "$@" >> "$LOG_FILE" 2>> "$ERROR_FILE"    # Redirect stdout and stderr to log files
    if [ $? -ne 0 ]; then
        echo "Error occurred during: $*" | tee -a "$ERROR_FILE"
    fi
}

# Clone latest node release
clone_latest_node_release() {
    REPO_URL="https://github.com/moneill-qoc/UENodeRelease.git"

    # Check if Git is installed
    if ! command -v git &>/dev/null; then
            echo "Git is not installed. Installing Git..."
    
        # Update package lists and install Git
        sudo apt update
        sudo apt install -y git
    
        # Verify installation
        if command -v git &>/dev/null; then
            echo "Git has been successfully installed."
        else
            echo "Git installation failed. Please check your package manager."
        fi
    else
        echo "Git is already installed. Version: $(git --version)"
    fi
    
    # Check if git-lfs is installed on Raspbian
    if ! command -v git-lfs &> /dev/null; then
        echo "Git LFS is not installed. Installing Git LFS..."
        sudo apt-get update && sudo apt-get install -y git-lfs
        echo "Git LFS installed successfully."
    else
        echo "Git LFS is already installed."
    fi
    
    # Ask user for a directory name for the install scripts
    read -p "Enter the runtime directory name [Default: Runtime]: " RT_DIR_NAME
    RT_DIR_NAME=${RT_DIR_NAME:-Runtime}
    echo
    
    # Make sure runtime directory does not exist and create it
    if [ ! -d "/tmp/$RT_DIR_NAME" ]; then
        echo "Creating directory /tmp/$RT_DIR_NAME..."
        mkdir "/tmp/$RT_DIR_NAME"
    else
        echo "Directory already exists. Removing it and recreating it..."
        sudo rm -r /tmp/$RT_DIR_NAME
        mkdir "/tmp/$RT_DIR_NAME"
    fi
    if [ -d "/tmp/$RT_DIR_NAME" ]; then
        cd "/tmp/$RT_DIR_NAME"
    else
        echo "/tmp/$RT_DIR_NAME was not created, exiting..."
        exit 1
    fi
    
    # Set parameters to increase buffers
    git config --global http.postBuffer 524288000
    git config --global http.maxRequestBuffer 524288000
    
    echo " Fetching releases from the QOC public repository."
    readarray -t gh_tags < <(git ls-remote --tags $REPO_URL | awk -F'/' '{print $3}' | grep -v '\^{}' | sort -r)
    latest_release=${gh_tags[0]}
    echo "Latest release of Node software: $latest_release"
    
    # Turn off detached HEAD advice
    git config --global advice.detachedHead false

    # Clone repository
    echo
    echo "Cloning $latest_release to $HOME/$RT_DIR_NAME"
    git clone --branch "$latest_release" "$REPO_URL"
}


# Main script execution
log_and_run clone_latest_node_release
log_and_run cd /tmp/Runtime/UENodeRelease/tarballs
log_and_run ./extract_node_tarball.sh
log_and_run cd $HOME/Runtime/NodeFiles/InstallationScripts
log_and_run ./install_packages.sh
log_and_run ./configure_rpi.sh
log_and_run ./install_node_files.sh
log_and_run sudo reboot

