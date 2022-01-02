terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {}

module "todo" {
  source         = "./modules/todo"
  ssh_public_key = file("~/.ssh/id_ed25519.pub")
}

output "app_url" {
  value = module.todo.app_url
}
