# Resources

Resources are the objects that Terraform should create, read, update, or delete
such as an AWS EC2 instance, an Azure virtual network, a GitHub repository, a
PagerDuty schedule, etc.

Providers offer different resources for use.

## Defining Resources

Resources are defined inside resource blocks.

```hcl
resource "aws_instance" "app" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
}
```

The resource block expects two labels; the resource type (`aws_instance`) and
the resource name (`app`).

Together, the resource type and resource name serve as a unique identifier for
a resource.

## Resource Types

Resource types follow the syntax `PROVIDER_RESOURCE`.

The `aws_instance` resource type refers to the `instance` resource within the
`aws` provider. Similarly, the `azurerm_linux_virtual_machine` resource type
refers to the `linux_virtual_machine` resource within the `azurerm` provider.

## Attributes vs. Arguments

Every resource has attributes associated with it that differ depending on the
resource type.

Attributes that you can set are called arguments. Attributes that you cannot
set are called read-only attributes. The documentation for a resource details
which attributes are arguments and which attributes are read-only attributes.

Some attributes will not be known until after a resource is created. For
example, an instance's public IP address.

We'll use the term attributes to refer to both attributes and arguments and
only make a distinction when necessary.

## Accessing Resource Attributes

Resource attributes can be accessed using the syntax `TYPE.NAME.ATTRIBUTE`.

```hcl
resource "aws_key_pair" "user" {
  key_name   = "user"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
}

resource "aws_instance" "app" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.user.id
}
```

## Resource Dependencies

Resources can have dependencies on other resources. When resource A is
dependent on resource B, resource B will be created or updated before resource
A is created or updated. Similarly, resource A will be destroyed before
resource B can be destroyed.

Resources without dependencies will be created, updated, or destroyed in
parallel.

### Implicit Dependencies

When one resource accesses an attribute from another resource, it creates an
implicit dependency between those resources.

```hcl
resource "aws_key_pair" "user" {
  key_name   = "user"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
}

resource "aws_instance" "app" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.user.id
}
```

### Explicit Dependencies

Use `depends_on` to create a resource dependency that Terraform cannot infer.

```hcl
resource "aws_instance" "app" {
  depends_on = [
    aws_instance.db
  ]

  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
}

resource "aws_instance" "db" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
}
```

## Meta-Arguments

All resources support the following meta-arguments that can be used to
change their behavior:

- `depends_on` - Explicitly define dependencies.
- `count` - Create multiple resources using indices.
- `for_each` - Create multiple named resources using keys.
- `provider` - Select a specific provider to use for the resource.
- `lifecycle` - Customize the resource lifecycle.
- `provisioner` - Provision a given resource after creation or destruction.
