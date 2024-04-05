#!/bin/bash

# Check if the 'warnet' directory exists
if [ ! -d "warnet" ]; then
    echo "Error: Warnet directory not found. Make sure to clone Warnet before running this script."
    exit 1
fi

# Check if the correct number of arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <network_name>"
    exit 1
fi

network_name="$1"

# Capture the current working directory, which has the attackathon files in it
current_directory=$(pwd)
sim_files="$current_directory/attackathon/data/$network_name"

echo "💣 Bringing up warnet 💣"
warcli network start "$sim_files/$network_name.graphml" --force

echo "Opening channels and syncing gossip"
warcli scenarios run ln_init

echo "Waiting for gossip to sync"
while warcli scenarios active | grep -q "True"; do
    sleep 1
done
