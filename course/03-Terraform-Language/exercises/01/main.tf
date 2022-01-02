terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {}

provider "aws" {
  alias  = "secondary"
  region = "us-west-1"
}

locals {
  ssh_info_primary   = "ssh -l ubuntu ${aws_instance.primary.public_ip}"
  ssh_info_secondary = "ssh -l ubuntu ${aws_instance.secondary.public_ip}"
}

# Required variables.
variable "ssh_public_key" {
  type = string
}

# Optional variables.
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

output "ssh_info_primary" {
  value = local.ssh_info_primary
}

output "ssh_info_secondary" {
  value = local.ssh_info_secondary
}
