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

file_name=$(basename "$json_file" .json)
echo "Setting up network for $file_name"

echo "Generating sim-ln file for historical payment generation"
simfile="$current_directory/attackathon/data/"$file_name"_simln.json"
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

