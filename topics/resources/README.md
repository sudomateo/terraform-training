# Resources

Resources represent the objects that Terraform should create, read, update, or delete. Objects such as an AWS EC2 instance, an Azure virtual network, a GitHub repository, a PagerDuty schedule, etc.

## Resource Syntax

Resources are defined inside resource blocks.

```hcl
resource "aws_instance" "example_app" {
  ami           = "ami-033b95fb8079dc481"
  instance_type = "t2.micro"
}
```

This resource block declares a resource with:

- A resource type of `aws_instance`.
- A name of `example_app`.
- Attributes in the body (within `{` and `}`).

Together, the resource type and name server as an identifier for a resource. As such, they must be unique within a given Terraform module.

## Resource Types

Every resource in Terraform has a resource type that determines what object it refers to and what attributes it supports.

Resource types follow the syntax `PROVIDER_RESOURCE`.

The `aws_instance` resource type from above refers to the `instance` resource within the `aws` provider.

Similarly, the `azurerm_linux_virtual_machine` resource type refers to the `linux_virtual_machine` resource within the `azurerm` provider.

We'll cover providers more in depth later, but just know that providers are Terraform plugins that allow Terraform to communicate with APIs. Each provider provides resource types that can be used in Terraform configuration.

## Resource Arguments and Attributes

Every resource has attributes associated with it. Attributes that you can set are called arguments. Attributes that you cannot set are called read-only attributes. The documentation for a resource details which attributes are arguments and which attributes are read-only attributes.

In the `aws_instance` example above, `ami` and `instance_type` are attributes. However, since they can both be set in the configuration, they are also known as arguments.

We'll use the term attributes to refer to both attributes and arguments and only make a distinction when necessary.

## Accessing Resource Attributes

Resource attributes can be accessed using the syntax `RESOURCE_TYPE.NAME.ATTRIBUTE`.

For example:

```hcl
resource "aws_instance" "example_app" {
  ami           = "ami-033b95fb8079dc481"
  instance_type = "t2.micro"
}

resource "aws_instance" "example_db" {
  ami           = aws_instance.example_app.ami
  instance_type = "t2.micro"
}
```

In the above example, the `aws_instance.example_db` resource is accessing the `ami` attribute from the `aws_instance.example_app` resource.

Some resources have read-only attributes that won't be known until the resource has been created. The documentation for a resource will list such attributes.

## Resource Dependencies

TODO

## Resource Meta-Arguments

TODO
