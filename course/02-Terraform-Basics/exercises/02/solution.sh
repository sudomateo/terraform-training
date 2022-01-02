#!/bin/bash

# 1. Create the infrastructure defined in main.tf and main.tf.json.
# 2. SSH into the virtual machine.
# 3. Run the commands in this script on the virtual machine.

sudo apt update

sudo apt install -y nginx

sudo systemctl enable --now nginx
