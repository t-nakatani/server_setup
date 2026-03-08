#!/bin/bash

echo "Starting Docker setup..."
chmod +x ./docker-setup.sh
./docker-setup.sh

echo "Starting Zsh setup..."
chmod +x ./zsh-setup.sh
./zsh-setup.sh

echo "Starting UFW firewall setup..."
chmod +x ./ufw-setup.sh
./ufw-setup.sh

echo "Starting unattended-upgrades setup..."
chmod +x ./unattended-upgrades-setup.sh
./unattended-upgrades-setup.sh

echo "All setups are complete."
