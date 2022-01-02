# Modules

In this section, you will learn how to do the following:

- Describe what modules are and when to use them.
- Create and use a module.
- Understand the different module sources.
- Declare providers within modules.

## What are Modules?

A module is a directory that contains Terraform configuration.

### Root Modules

The directory that you execute Terraform against is known as the root module.
The root module is similar to the main, or entrypoint, function in programming.

```
> tree
.
└── main.tf
```

### Child Modules

Modules are directories containing Terraform configuration that can be included
when executing Terraform.

The root module can call other modules to include their resources, data
sources, and outputs into the configuration. A module that calls another module
is called the parent module. The module that a parent module calls is called
the child module.

```
> tree
.
├── main.tf
└── modules
    └── app
        └── main.tf
```

## Using Modules

Modules are called using `module` blocks. Input variables for modules can be
passed to the module as attributes.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {}

module "app" {
  source = "./modules/app"

  # Input variables for the modules.
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
}
```

## Developing Modules

Develop a module to create abstractions by grouping together multiple related
resources. 

Modules follow this directory structure.

```
.
├── main.tf
├── outputs.tf
└── variables.tf
```

- Resources, data sources, and Terraform settings are placed in `main.tf`.
- Input variables are declared in `variables.tf`.
- Output values are declared in `outputs.tf`.

As your module configuration becomes more complex, it may be necessary to
further split out your configuration. While there's no standard for how to
split out `main.tf`, here's a common structure that you'll see in the field.

```
.
├── main.tf
├── data.tf
├── locals.tf
├── outputs.tf
└── variables.tf
```

### Resources and Data Sources

Place the resources and data sources that you want your module to manage in
`main.tf`.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {}

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

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.app.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
}

resource "aws_key_pair" "app" {
  key_name   = "app"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "app" {
  name        = "app"
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
```

### Input Variables

Place any variables that your module needs in `variables.tf`

```hcl
variable "ssh_public_key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
```

### Output Values

```hcl
output "ssh_info" {
  value = "ssh -l ubuntu ${aws_instance.app.public_ip}"
}
```

## Providers in Modules

Declare the providers that your module uses using the `required_providers`
syntax. This will prevent callers from using your module with incompatible
provider versions.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
```

### Provider Aliasing

If your module requires aliased providers, they must be declared using the
`configuration_aliases` attribute. This is useful when writing modules that
require multiple provider configurations.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
      configuration_aliases = [aws.secondary]
    }
  }
}
```

### Passing Providers to Modules

Provider configuration must not be present in a module. This is because when a
module is removed from the configuration, the provider will be removed as well
and Terraform won't know how to communicate with the upstream API to remove the
resources within the module.

Instead, pass modules from the root module down to child modules.

```hcl
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

module "app" {
  source = "./modules/app"

  providers = {
    # The base provider does not need to be explicitly passed.
    aws = aws

    # Aliased providers do need to be explicitly passed.
    aws.secondary = aws.secondary
  }

  # Input variables for the modules.
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
}
```

### Orphaning Providers

Declaring a `provider` block in a module will lead to issues when attempting to
destroy the module.

`main.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


# This is commented out simulate removing it from the configuration.
# module "app" {
#   source = "./modules/app"
#
#   # Input variables for the modules.
#   ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
# }
```

`modules/app/main.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# This provider block should not be declared within a module.
provider "aws" {}

# ...
```

With the module removed, Terraform no longer knows what provider to use to
destroy the resources.

```
> terraform apply
╷
│ Error: Provider configuration not present
│ 
│ To work with module.app.aws_instance.app (orphan) its original provider configuration at
│ module.app.provider["registry.terraform.io/hashicorp/aws"] is required, but it has been removed. This
│ occurs when a provider configuration is removed while objects created by that provider still exist in
│ the state. Re-add the provider configuration to destroy module.app.aws_instance.app (orphan), after
│ which you can remove the provider configuration again.
╵
╷
│ Error: Provider configuration not present
│ 
│ To work with module.app.aws_key_pair.app (orphan) its original provider configuration at
│ module.app.provider["registry.terraform.io/hashicorp/aws"] is required, but it has been removed. This
│ occurs when a provider configuration is removed while objects created by that provider still exist in
│ the state. Re-add the provider configuration to destroy module.app.aws_key_pair.app (orphan), after
│ which you can remove the provider configuration again.
╵
╷
│ Error: Provider configuration not present
│ 
│ To work with module.app.aws_security_group.app (orphan) its original provider configuration at
│ module.app.provider["registry.terraform.io/hashicorp/aws"] is required, but it has been removed. This
│ occurs when a provider configuration is removed while objects created by that provider still exist in
│ the state. Re-add the provider configuration to destroy module.app.aws_security_group.app (orphan),
│ after which you can remove the provider configuration again.
╵
```

## Module Sources

Terraform must be told where to find the configuration for a module by using
the `source` attribute. Depending on the source, Terraform must download the
module source code before it can be used to manage resources.

### Local Paths

Use a local path to reference a module on the local filesystem.

```hcl
module "app" {
  source = "./modules/app"

  # Input variables for the modules.
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
}
```

### Terraform Registry

Modules in the [Terraform Registry](https://registry.terraform.io) can be used
using the source format `NAMESPACE/NAME/PROVIDER`.

```hcl
module "nomad" {
  source  = "hashicorp/nomad/aws"

  # ...
}
```

#### Module Versions

To use a specific version of a module, pass the `version` attribute.

```hcl
module "nomad" {
  source  = "hashicorp/nomad/aws"
  version = "0.10.0"

  # ...
}
```

### Git Repositories

Use modules from a Git repository using SSH.

```hcl
module "app" {
  source = "git::ssh://username@example.com/app.git"
}
```

Use modules from a Git repository using HTTPS.

```hcl
module "app" {
  source = "git::https://example.com/app.git"
}
```

Select a specific revision of the module using the `ref` query parameter.

```hcl
module "app" {
  source = "git::ssh://username@example.com/app.git?ref=v1.0.0"
}
```

#### Modules in Sub-directories

If the module that you need is in a sub-directory, use a `//` to find it.

```hcl
module "app" {
  source = "git::ssh://username@example.com/app.git//modules/app?ref=v1.0.0"
}
```

## Publishing Modules to the Terraform Registry

You can publish and share modules on the
[Terraform Registry](https://registry.terraform.io).

### Requirements for Publishing a Module

To publish a module on the [Terraform Registry](https://registry.terraform.io):

- The module source code must be in a public repository on GitHub.
- The name of the repository must follow the format `terraform-PROVIDER-NAME`
  where `PROVIDER` is the primary provider for the module and `NAME` is the
  name of the module.
- The module must follow the standard module structure by having a `main.tf`,
  `variables.tf`, and `outputs.tf`. These will be inspected by the registry to
  display variables, outputs, and submodules to the user.
- The repository must use the tag format `x.y.z` for releases. Each release can
  be optionally prefixed with a `v`.
