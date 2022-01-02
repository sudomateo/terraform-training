#!/bin/bash

# Create the key pair.
aws ec2 import-key-pair --key-name example --public-key-material "$(base64 -w 0 ~/.ssh/id_ed25519.pub)"

# Create the security group.
group_id="$(aws ec2 create-security-group --group-name example --description "Example security group." --output text --query 'GroupId')"
aws ec2 authorize-security-group-ingress --group-id "${group_id}" --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create the virtual machine.
aws ec2 run-instances --image-id ami-007855ac798b5175e --instance-type t3.micro --security-group-ids "${group_id}" --key-name example --associate-public-ip-address
