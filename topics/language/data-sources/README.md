# Data Sources 

Data sources are a special kind of Terraform resource that reads information
and exposes that information for use within your Terraform configuration.

Providers may offer data sources in addition to their resources.

## Defining Data Sources

Data sources are defined inside data blocks.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  # Canonical's account ID.
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

The data source block expects two labels; the data source type (`aws_ami`) and
the data source name (`ubuntu`).

Together, the data source type and data source name serve as a unique identifier
for a data source.

## Data Source Types

Like resource types, data source types follow the syntax `PROVIDER_DATASOURCE`.

The `aws_ami` data source type refers to the `ami` data source within the `aws`
provider.

## Attributes vs. Arguments

Like resources, every data source has attributes associated with it that differ
depending on the data source type.

Attributes that you can set are called arguments. Attributes that you cannot
set are called read-only attributes. The documentation for a resource details
which attributes are arguments and which attributes are read-only attributes.

Attributes on data sources are usually used to filter what information the data
source should retrieve.

## Accessing Data Source Attributes

Data source attributes can be accessed using the syntax
`data.TYPE.NAME.ATTRIBUTE`.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  # Canonical's account ID.
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

## Data Source Dependencies

Like resources, data sources can have dependencies on other resources or data
sources. When data source A is dependent on data source B, data source B will
be read before data source A is read. Similarly, data source A will be
destroyed before data source B can be destroyed.

Data sources without dependencies will be read in parallel.

## Meta-Arguments

Data sources support all of the meta-arguments that resources do except
`lifecycle`.
