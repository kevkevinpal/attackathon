#!/bin/bash

if [ ! -d "warnet" ]; then
    git clone https://github.com/bitcoin-dev-project/warnet
fi

cd warnet

# TODO: pin to a certain commit
# git checkout XYZ 

python3 -m venv .venv  # Use alternative venv manager if desired
source .venv/bin/activate
pip install --upgrade pip
pip install -e .

warnet 
