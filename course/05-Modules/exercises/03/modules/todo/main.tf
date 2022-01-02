terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical's AWS account ID.
}

data "aws_vpc" "default" {
  default = true
}

locals {
  user_data = <<EOF
#!/bin/bash

# Install dependencies.
sudo apt update && sudo apt install -y ca-certificates curl gnupg

# Docker GPG key configuration.
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Docker repository configuration.
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker.
sudo apt update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

# Run todo application.
docker run --detach --name todo --publish ${var.app_port}:${var.app_port} \
  --env TODO_ADDR=:${var.app_port} \
  --env TODO_DATABASE_HOST=${aws_db_instance.db.address} \
  --env TODO_DATABASE_USER=${var.db_user} \
  --env TODO_DATABASE_PASSWORD=${var.db_password} \
  --env TODO_DATABASE_NAME=${var.db_name} \
  --env TODO_VERSION=${var.app_version} \
ghcr.io/sudomateo/todo:latest
EOF
}
