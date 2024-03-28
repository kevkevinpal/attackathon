#!/bin/bash

if [ ! -d "warnet" ]; then
    echo "Error: Warnet directory not found. Make sure to clone Warnet before running this script."
    exit 1
fi

# Capture current working directory, which has the attackathon files in it.
current_directory=$(pwd)

cd warnet

python3 -m venv .venv
source .venv/bin/activate

echo "Preparing historical data"
python3 "$current_directory/attackathon/setup/progress_timestamps.py" "$current_directory/attackathon/data/ln_10_raw_data.csv" "$current_directory/attackathon/data/ln_10_data.csv"

echo "💣 Bringing up warnet 💣"
warcli network start "$current_directory/attackathon/data/ln_10.graphml" --force

echo "Opening channels and syncing gossip"
warcli scenarios run ln_init 

echo "Waiting for gossip to sync"
while warcli scenarios active | grep -q "True"; do
    sleep 1
done

echo "TODO: sim-ln is not currently included"
echo "TODO: Running attack scenario"

