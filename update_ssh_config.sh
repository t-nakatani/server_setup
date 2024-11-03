#!/bin/bash

# sshd_config path
CONFIG_FILE="/etc/ssh/sshd_config"

# backup
cp $CONFIG_FILE "${CONFIG_FILE}.bak"

# port
sed -i 's/^#Port 22/Port 53122/' $CONFIG_FILE

# password
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' $CONFIG_FILE
sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' $CONFIG_FILE

# root login
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' $CONFIG_FILE

# check sshd_config syntax, then restart sshd
sshd -t
systemctl restart sshd
