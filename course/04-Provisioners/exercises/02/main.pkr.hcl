data "amazon-ami" "ubuntu" {
  filters = {
    virtualization-type = "hvm"
    name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
    root-device-type    = "ebs"
  }
  owners      = ["099720109477"]
  most_recent = true
}

source "amazon-ebs" "app" {
  ami_name      = "app_{{timestamp}}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  source_ami    = data.amazon-ami.ubuntu.id
  ssh_username  = "ubuntu"
  ssh_interface = "public_ip"
  communicator  = "ssh"
}

build {
  sources = ["source.amazon-ebs.app"]

  provisioner "file" {
    source      = "install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "shell" {
    inline = [
      "/tmp/install.sh",
      "rm /tmp/install.sh",
    ]
  }
}
