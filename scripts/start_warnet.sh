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

docker_info=$(docker info)

if grep -q "Context:.*desktop" <<< "$docker_info"; then
    echo "Starting warnet for docker desktop."
    just startd
else
    echo "Starting warnet for docker."
    just start
fi

# Port forward for warcli
echo "Port forwarding from kubernetes to warnet cluster for warcli (don't close this!)"
just p
