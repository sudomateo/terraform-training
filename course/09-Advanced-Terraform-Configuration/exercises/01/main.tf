terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {}

module "vm" {
  source = "./modules/vm"

  virtual_machines = {
    sudomateo = {
      ssh_public_key = file("~/.ssh/id_ed25519.pub")
      instance_type  = "t3.small"
      ingress_rules = [
        {
          description = "SSH"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
        },
        {
          description = "HTTP"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
        }
      ]
    }

    alice = {
      ssh_public_key = file("~/.ssh/id_ed25519.pub")
      ingress_rules = [
        {
          description = "SSH"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
        }
      ]
    }
  }
}
