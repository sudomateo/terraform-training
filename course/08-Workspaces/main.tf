terraform {
  backend "s3" {
    bucket         = "terraform-training20230420004138989500000001"
    key            = "terraform/states/todo"
    region         = "us-east-1"
    dynamodb_table = "terraform-training"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {}

variable "ssh_public_key" {
  type = string
}

module "todo" {
  source = "./modules/todo"

  ssh_public_key = var.ssh_public_key
}

output "ssh_info" {
  value = module.todo.ssh_info
}

output "app_url" {
  value = module.todo.app_url
}
