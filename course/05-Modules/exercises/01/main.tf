terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "ssh_public_key" {
  type = string
}

module "app" {
  source = "./modules/app"

  ssh_public_key = var.ssh_public_key
  user_data      = <<EOF
#!/bin/bash

sudo apt update
sudo apt install -y nginx
sudo systemctl enable --now nginx
EOF
}

output "app_url" {
  value = "http://${module.app.instance.public_ip}"
}
