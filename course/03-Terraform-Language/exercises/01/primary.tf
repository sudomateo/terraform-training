data "aws_ami" "primary" {
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

resource "aws_instance" "primary" {
  ami                    = data.aws_ami.primary.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.primary.key_name
  vpc_security_group_ids = [aws_security_group.primary.id]
}

resource "aws_key_pair" "primary" {
  key_name   = "primary"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "primary" {
  name        = "primary"
  description = "Inbound: SSH. Outbound: all."

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
