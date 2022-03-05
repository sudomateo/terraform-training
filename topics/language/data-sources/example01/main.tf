# This data source retrieves information about the latest Ubuntu 20.04 AMI from
# Canonical.
#
# If Canonical were to publish a new Ubuntu 20.04 AMI, the next execution of
# this data source would find it and retrieve its information instead.
data "aws_ami" "example_ubuntu" {
  owners      = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# This resource uses the retrieved AMI ID from the data source above.
resource "aws_instance" "example_app" {
  ami           = data.aws_ami.example_ubuntu.id
  instance_type = "t2.micro"
}
