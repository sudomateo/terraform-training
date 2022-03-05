# Data Sources 

Data sources allow Terraform to access information about other resources that may have been created outside of Terraform, created by a different Terraform configuration, or may have changed out of band.

## Data Source Syntax

Data sources are defined inside data resource blocks.

```hcl
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
```

This data resource block declares a data source with:

- A data source type of `aws_ami`.
- A name of `example_ubuntu`.
- Attributes in the body (within `{` and `}`).

Together, the data source type and name serve as an identifier for a data source. As such, they must be unique within a given Terraform module.

## Data Source Types

Like resource types, data source types follow the syntax `PROVIDER_RESOURCE`.

The `aws_ami` data source type from above refers to the `ami` data soruce within the `aws` provider.

## Data Source Arguments and Attributes

Like resources, data sources have attributes associated with it. Attributes that you can set are called arguments. Attributes that you cannot set are called read-only attributes. The documentation for a data source details which attributes are arguments and which attributes are read-only attributes.

In the `aws_ami` example above, `owners`, `most_recent`, and `filter` are attributes. However, since they can both be set in the configuration, they are also known as arguments. These arguments are used to read a given data source and retrieve other attributes that can be referenced elsewhere in the configuration.

## Accessing Data Source Attributes

Resource attributes can be accessed using the syntax `data.DATA_SOURCE_TYPE.NAME.ATTRIBUTE`.

For example:

```hcl
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

resource "aws_instance" "example_app" {
  ami           = data.aws_ami.example_ubuntu.id
  instance_type = "t2.micro"
}
```

In the above example, the `aws_instance.example_app` resource is accessing the `id` attribute from the `data.aws_ami.example_ubuntu` data source.

## Data Source Dependencies

Like resources, data sources can have implicit, explicit, or no dependencies. However, since data sources are used to retrieve information about other resources, it's a good idea to keep any dependencies to a minimum.

## Data Source Meta-Arguments

Data sources support all of the meta-arguments that resources do except `lifecycle`.
