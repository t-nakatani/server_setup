#!/bin/bash

echo "Starting Docker setup..."
chmod +x ./docker-setup.sh
./docker-setup.sh

echo "Starting Zsh setup..."
chmod +x ./zsh-setup.sh
./zsh-setup.sh

echo "All setups are complete." 
