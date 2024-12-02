#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Clone latest node release
clone_latest_node_release() {
    REPO_URL="https://github.com/QOC-Innovations/UENode-Public.git"

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

#    # Check if git-lfs is installed on Raspbian
#    if ! command -v git-lfs &> /dev/null; then
#        echo "Git LFS is not installed. Installing Git LFS..."
#        sudo apt-get update && sudo apt-get install -y git-lfs
#        echo "Git LFS installed successfully."
#    else
#        echo "Git LFS is already installed."
#    fi

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
        mkdir -p /tmp/$RT_DIR_NAME
        echo "   ===> /tmp/$RT_DIR_NAME has been recreated..."
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

    echo "Fetching releases from the QOC public repository."
    readarray -t gh_tags < <(git ls-remote --tags $REPO_URL | awk -F'/' '{print $3}' | grep -v '\^{}' | sort -r)
    latest_release=${gh_tags[0]}
    echo "Latest release of Node software: $latest_release"

    # Turn off detached HEAD advice
    git config --global advice.detachedHead false

    # Clone repository
    echo
    echo "Cloning $latest_release to /tmp/$RT_DIR_NAME"
    git clone --branch "$latest_release" "$REPO_URL"
}

check_for_locks() {
    max_retries=10  # Maximum number of retries
    retry_count=0
    retry_delay=5  # Time to wait (in seconds) before retrying

    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        echo "Another process is using dpkg. Waiting for lock to be released..."
        ((retry_count++))
        if [ "$retry_count" -ge "$max_retries" ]; then
            echo "Max retries reached. Could not acquire lock."
            exit 1
        fi
        sleep "$retry_delay"
    done

    echo "Lock released. Proceeding with package installation..."

}


##############################################
# Main Execution
##############################################

clone_latest_node_release
cd /tmp/Runtime/UENode-Public/tarballs
./extract_node_tarball.sh
cd $HOME/Runtime/NodeFiles/InstallationScripts
check_for_locks
./install_packages.sh
./configure_rpi.sh
./install_node_files.sh
sudo reboot

