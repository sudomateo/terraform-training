# Core Workflow

The core Terraform workflow has three steps:

1. Write - Create Terraform configuration.
1. Plan - Preview changes before applying.
1. Apply - Provision infrastructure.

```mermaid
flowchart LR
	write[Write]
	plan[Plan]
	apply[Apply]

	write --> plan --> apply
```

## Write

Write Terraform configuration to define your infrastructure.

Create a `main.tf` file with the following content:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.22.0"
    }
  }
}

# AWS credentials are read from the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# environment variables to prevent leaking secrets.
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
}
```

Initialize this Terraform configuration to set up the backend and download the
necessary Terraform providers.

```
terraform init
```

## Plan

When you are satisfied with your configuration, preview the changes that
Terraform plans to make.

```
terraform plan
```

If the plan shows changes that you didn't expect, go back and update your
configuration and preview your changes in a new plan.

## Apply

Once the plan looks good, tell Terraform to apply the changes.

```
terraform apply
```

Terraform will prompt for confirmation before applying.

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```
