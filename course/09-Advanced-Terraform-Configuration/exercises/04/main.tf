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
  source = "./modules/todo"

  ssh_public_key = file("~/.ssh/id_ed25519.pub")
  ingress_port   = 8888
  active_app     = "blue"

  app_blue = {
    version = "blue"
  }

  app_green = {
    version = "green"
  }

  db = {
    password = "ifitsfreeitsterraforme"
  }
}

output "app_url" {
  value = module.todo.app_url
}
