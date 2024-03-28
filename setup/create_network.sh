#!/bin/bash

usage() {
    echo "Usage: $0 <json_file_path> <duration>"
    echo "Example: $0 /path/to/file.json 10s"
    exit 1
}

if [ ! -d "warnet" ]; then
    echo "Error: Warnet directory not found. Make sure to clone Warnet before running this script."
    exit 1
fi

if [ ! -d "sim-ln" ]; then
    echo "Error: Sim-LN directory not found. Make sure to clone Sim-LN before running this script."
	exit 1
fi

if ! command -v rustc &> /dev/null; then
    echo "Error: Rust compiler (rustc) is not installed. Please install Rust from https://www.rust-lang.org/."
    exit 1
fi

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    usage
fi

json_file="$1"
duration="$2"

current_directory=$(pwd)

# Check if JSON file exists
if [ ! -f "$json_file" ]; then
    echo "Error: JSON file '$json_file' not found."
    exit 1
fi

network_name=$(basename "$json_file" .json)
echo "Setting up network for $network_name"

sim_files="$current_directory"/attackathon/data/"$network_name"
echo "Creating simulation files in: "$sim_files""
mkdir -p $sim_files

echo "Generating sim-ln file for historical payment generation"
simfile="$sim_files"/simln.json
python3 attackathon/setup/lnd_to_simln.py "$json_file" "$simfile"
cd sim-ln

if [[ -n $(git status --porcelain) ]]; then
    echo "Error: there are unsaved changes in sim-ln, please stash them!"
    exit 1
fi

# Grab branch that has data writing.
git remote add carla https://github.com/carlaKC/sim-ln

# Silence some of the louder output.
git fetch carla > /dev/null 2>&1 
git checkout carla/sim-data > /dev/null 2>&1 

echo "Installing sim-ln for data generation"
cargo install --locked --path sim-cli

# Clean up after ourselves.
git remote remove carla
git checkout main > /dev/null 2>&1 

echo "Generating historical data for $duration seconds, this might take a while!"
sim-cli -l debug -c 10 -s "$simfile" -t "$duration"

# Copy the raw sim-ln data from its output folder to our attackathon data dir. 
raw_data="$sim_files"/raw_data.csv
cp results/htlc_forwards.csv "$raw_data"
cd ..

# Set the location where we'll output our progressed timestamp output.
processed_data="$sim_files"/data.csv

# Before we actually bump our timestamps, we'll spin up warnet to generate a graphml file that
# will use our generated data.
echo "Generating warnet file for network"
cd warnet 
python3 -m venv .venv > /dev/null 2>&1 
source .venv/bin/activate > /dev/null 2>&1 
pip install -e . > /dev/null 2>&1 

# Run warnet in the background and capture pid for shutdown.
# NB!!! currently running on: https://github.com/carlaKC/warnet/tree/attackathon-network
warnet &
warnet_pid=$!

warnet_file="$sim_files"/"$network_name".graphml
warcli graph import-json "$json_file" --cb_data="$processed_data" --outfile="$warnet_file" > /dev/null 2>&1 

# Shut warnet down
kill $warnet_pid
wait $warnet_pid 2>/dev/null

cd ..

# Finally, progress our timstamps so that we're ready to roll!
# The user-provided scripts should do this anyway, but we update them to know it works.
python3 ./attackathon/setup/progress_timestamps.py "$raw_data" "$processed_data"

echo "Setup complete!"

echo "Check in your data files and tell participants to run with network name: $network_name"
