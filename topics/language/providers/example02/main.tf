terraform {
  required_providers {
    # Require version `4.4.0` of the `hashicorp/aws` provider from the official
    # Terraform Registry. Give it the local name `aws-custom`.
    aws-custom = {
      source  = "hashicorp/aws"
      version = "4.4.0"
    }
  }
}

# Configure the unaliased `aws-custom` provider. Read `access_key` and
# `secret_key` from the environment variables `AWS_ACCESS_KEY_ID` and
# `AWS_SECRET_ACCESS_KEY`.
provider "aws-custom" {
  region = "us-east-1"
}

# Create an `aws_instance` resource using the unaliased `aws-custom` provider.
# Note that the `provider` attribute is necessary to tell Terraform which
# of the required providers to use.
resource "aws_instance" "example_app" {
  provider = aws-custom

  ami           = "ami-0c293f3f676ec4f90"
  instance_type = "t2.micro"
}
