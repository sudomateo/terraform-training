# Provisioning Infrastructure

Let's use the core Terraform workflow (write, plan, apply) to provision an EC2
instance in AWS.

## Write

Write Terraform configuration to define your infrastructure.

Create a `main.tf` file with the following content:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# AWS credentials are read from the AWS CLI or environment variables.
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app" {
  ami           = "ami-052efd3df9dad4825"
  instance_type = "t3.micro"

  tags = {
    Name        = "app"
    Environment = "Development"
  }
}
```

### Initializing Configuration

Terraform configuration must be initialized before Terraform can perform
operations against it.

The initialization process:

- Configures the backend.
- Downloads and installs provider plugins.
- Downloads modules.

```
terraform init
```

This initialization output shows that Terraform successfully initialized the
configuration and downloaded the `hashicorp/aws` provider.

```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 4.0"...
- Installing hashicorp/aws v4.24.0...
- Installed hashicorp/aws v4.24.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!
```

## Plan

Once your configuration is written and initialized, preview the changes that
Terraform plans to make.

```
terraform plan
```

This plan output shows that Terraform plans to create a new `aws_instance`
resource.

```
Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.app will be created
  + resource "aws_instance" "app" {
      + ami                                  = "ami-052efd3df9dad4825"
      + id                                   = (known after apply)
      + instance_type                        = "t3.micro"
      ...
      + tags                                 = {
          + "Environment" = "Development"
          + "Name"        = "app"
        }
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

If the plan shows changes that you didn't expect, go back and update your
configuration and preview your changes in a new plan.

## Apply

Once you are satisfied with the plan output, tell Terraform to apply the
changes.

```
terraform apply
```

Terraform will execute another plan and prompt for confirmation before
applying.

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```
