# Destroying Infrastructure

Part of the core Terraform workflow involves destroying infrastructure when
you're done with it.

## Destroying Specific Infrastructure

There will come a time when you'll want to destroy specific resources managed
by Terraform.

To do that, remove the resources that you no longer need from the
configuration.

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

# This is commented out to simulate removing this resource from the
# configuration.
# resource "aws_instance" "app" {
#   ami           = "ami-052efd3df9dad4825"
#   instance_type = "t3.micro"

#   tags = {
#     Name        = "app"
#     Environment = "Development"
#   }
# }
```

Then apply your configuration.

```
terraform apply
```

Terraform will detect that the resource you removed is no longer needed and it
will attempt to destroy it.

```
aws_instance.app: Refreshing state... [id=i-01498124dc55cc00e]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_instance.app will be destroyed
  # (because aws_instance.app is not in configuration)
  - resource "aws_instance" "app" {
      - ami                                  = "ami-052efd3df9dad4825" -> null
      - id                                   = "i-01498124dc55cc00e" -> null
      ...
      - tags                                 = {
          - "Environment" = "Development"
          - "Name"        = "app"
        } -> null
      ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

## Destroying All Managed Infrastructure

Terraform is commonly used to spin up ephemeral infrastructure for development.
Once that infrastructure has served its purpose you'll want to destroy it all.

To do that, run a destroy operation to tell Terraform to destroy all
infrastructure it manages.

```
terraform destroy
```

`terraform destroy` is just an alias for:

```
terraform apply -destroy
```

Terraform will execute a destroy plan and prompt for confirmation before
applying the destroy plan.

```
aws_instance.app: Refreshing state... [id=i-01498124dc55cc00e]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_instance.app will be destroyed
  - resource "aws_instance" "app" {
      - ami                                  = "ami-052efd3df9dad4825" -> null
      - id                                   = "i-01498124dc55cc00e" -> null
      ...
      - tags                                 = {
          - "Environment" = "Development"
          - "Name"        = "app"
        } -> null
      ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

### Speculative Destroy Plan

You can execute a speculative destroy plan to see what resources Terraform
would destroy without actually destroying them.

```
terraform plan -destroy
```
