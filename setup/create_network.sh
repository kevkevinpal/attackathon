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

# Check if JSON file exists
if [ ! -f "$json_file" ]; then
    echo "Error: JSON file '$json_file' not found."
    exit 1
fi

# Check if duration is valid
if ! [[ $duration =~ ^[0-9]+[smh]$ ]]; then
    echo "Error: Invalid duration format. Please provide duration in Linux duration format (e.g., 10s, 1m, etc)."
    exit 1
fi

file_name=$(basename "$json_file" .json)
echo "Setting up network for $file_name"

echo "Generating sim-ln file for historical payment generation"
python3 attackathon/setup/lnd_to_simln.py "$json_file" attackathon/data/"$file_name"_simln.json
