# Providers

Providers are plugins that add resources and data sources to Terraform that Terraform can create, read, update, and delete.

## Finding Providers

Terraform providers can be found on the [Terraform Registry](https://registry.terraform.io/browse/providers).

## Requiring Providers

Once you find a provider to use, you'll have to require it in your configuration. To require a provider, declare it inside a `required_providers` block within the special top-level `terraform` block.

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.4.0"
    }
  }
}
```

Each provider declared in `required_providers` uses the following syntax:

```hcl
LOCAL_NAME = {
	source = "SOURCE"
	version = "VERSION"
}
```

- `LOCAL_NAME` - The local name used to refer to this provider within the current module. Usually this will match the type within the `SOURCE`.
- `SOURCE` - Where to find the provider. In the format `[HOSTNAME/]NAMESPACE/TYPE` where an omitted `HOSTNAME` means use the official Terraform Registry.
- `VERSION` - The version constraint to use for the provider.

Given the above `required_providers` block, we can infer the following:

- The local name is `aws`.
- The source is `hashicorp/aws` meaning find the `aws` provider within the `hashicorp` namespace within the official Terraform Registry.
- The version constraint is `4.4.0` which means only use version `4.4.0` of the provider.

## Provider Configuration

Once your providers have been declared within `required_providers`, they must be configured so that Terraform can use them to communicate with their APIs.

Providers are configured via provider blocks.

```hcl
provider "aws" {
  access_key = "ABCXYZ"
  secret_key = "ABCXYZ"
  region     = "us-east-1"
}
```

Each provider has its own attributes that can be configured. Some of those attributes may be required while others are optional.

Providers can also read attribute values from environment variables. This approach is more secure since it does not store hard coded attributes in the configuration file.

```hcl
# The `access_key` attribute can be read from the `AWS_ACCESS_KEY_ID` environment variable.
# The `secret_key` attribute can be read from the `AWS_SECRET_ACCESS_KEY` environment variable.
provider "aws" {
  region = "us-east-1"
}
```

## Provider Aliasing

Sometimes you'll need to manage resources across different accounts or regions for the same provider. For these use cases, you'll want to use aliased providers.

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias = "west"
  region = "us-west-1"
}
```

Resources that do not specify a provider will use the default, or unaliased, provider.
```hcl
resource "aws_instance" "example_app" {
  ami           = "ami-0c293f3f676ec4f90"
  instance_type = "t2.micro"
}
```

To use an aliased provider within a resource, pass in the `provider` attribute.

```hcl
resource "aws_instance" "example_app" {
  provider = aws.west

  ami           = "ami-051317f1184dd6e92"
  instance_type = "t2.micro"
}
```
