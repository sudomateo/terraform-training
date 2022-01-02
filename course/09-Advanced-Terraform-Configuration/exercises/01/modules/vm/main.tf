terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "virtual_machines" {
  type = map(object({
    ssh_public_key = string,
    instance_type  = optional(string, "t3.micro")
    ingress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = optional(string, "tcp")
    }))
  }))
  default = {}
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

resource "aws_key_pair" "vm" {
  for_each        = var.virtual_machines
  key_name_prefix = each.key
  public_key      = each.value.ssh_public_key
}

resource "aws_security_group" "vm" {
  for_each    = var.virtual_machines
  name_prefix = each.key
  description = "Security group for ${each.key} virtual machine."
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = each.value.ingress_rules

    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "vm" {
  for_each               = var.virtual_machines
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = each.value.instance_type
  key_name               = aws_key_pair.vm[each.key].key_name
  vpc_security_group_ids = [aws_security_group.vm[each.key].id]

  tags = {
    Name = each.key
  }
}
