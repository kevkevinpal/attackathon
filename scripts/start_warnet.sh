#!/bin/bash

# Function to check if a command is available
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed."
        exit 1
    fi
}

check_command just
check_command docker

if [ ! -d "warnet" ]; then
    git clone https://github.com/bitcoin-dev-project/warnet
fi

cd warnet

# Check if the 'carla' remote exists
if ! git remote | grep -q '^carla$'; then
    echo "Remote 'carla' does not exist. Adding..."
    git remote add carla https://github.com/carlaKC/warnet
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "There are uncommitted changes in warnet, please stash them!"
    exit 1
fi

echo "Checking out custom branch of warnet"
echo "TODO: remove me when attackathon/18 has been addressed!"
git fetch carla > /dev/null 2>&1 || { echo "Failed to fetch carla"; exit 1; }
git checkout carla/attackathon > /dev/null 2>&1 || { echo "Failed to checkout carla/attackathon"; exit 1; }

docker_info=$(docker info)

if grep -q "Operating System:.*Desktop" <<< "$docker_info"; then
    echo "Starting warnet for docker desktop."
    just startd
else
    echo "Starting warnet for docker."
    just start
fi

# Port forward for warcli
echo "Port forwarding from kubernetes to warnet cluster for warcli (don't close this!)"
just p
