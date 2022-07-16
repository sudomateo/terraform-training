# Providers

Providers are plugins that Terraform uses to communicate with upstream CRUD
APIs.

## Finding Providers

You can search for providers on the
[Terraform Registry](https://registry.terraform.io/).

## Requiring Providers

Once you've found a provider, you'll have to require it in your Terraform
configuration.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.22.0"
    }
  }
}
```

## Configuring Providers

Most providers need to be configured before they can be used. Configuration
usually involves passing in credentials that are used to communicate with
upstream CRUD APIs.

```hcl
# AWS credentials are read from the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# environment variables to prevent leaking secrets.
provider "aws" {
  region = "us-east-1"
}
```

## Aliasing Providers

To define multiple configurations for the same provider, create a provider
alias. This is useful when you want to use the same provider in slightly
different ways, such as supporting multiple regions for a cloud platform.

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-1"
}
```

Resources that do not specify a provider will use the default, or unaliased,
provider.

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
}
```

To use an aliased provider within a resource, pass in the `provider` attribute.

```hcl
resource "aws_instance" "example" {
  provider      = aws.secondary
  ami           = "ami-0d9858aa3c6322f73"
  instance_type = "t3.micro"
}
```
