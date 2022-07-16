# Configuration Syntax

Terraform configuration is written in [HashiCorp Configuration Language
(HCL)](https://github.com/hashicorp/hcl) syntax or JSON syntax. HCL syntax is
the most common, and arguably the most readable, syntax for Terraform
configuration. JSON syntax is less common but it is useful when
programmatically generating Terraform configuration.

## HCL Syntax

Terraform configuration written in HCL syntax is stored in files with the `.tf`
file extension.

HCL syntax is built around two concepts; attributes and blocks.

### Attributes

An attribute assigns the value of an `EXPRESSION` to a particular `IDENTIFIER`:

```hcl
IDENTIFER = EXPRESSION
```

An `IDENTIFIER` can contain letters (`a-z`, `A-Z`), digits (`0-9`), underscores
(`_`), and hyphens (`-`). However, the first character of an `IDENTIFIER` must
not be a digit.

An `EXPRESSION` represents an attribute's value. This can either be a literal
value or a programmatically generated value.

Example attribute:

```hcl
image_id = "ami-123456"
```

### Blocks

A block is a container used to hold attributes and other blocks.

```hcl
TYPE "LABEL" "LABEL" {
  IDENTIFIER = EXPRESSION

  TYPE {
    IDENTIFIER = EXPRESSION
  }
}
```

A `TYPE` represents the block type. Block types tell Terraform what schema is
valid for the block.

Blocks can have zero or more `LABEL`s depending on the `TYPE`.

Example block:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-123456"
  instance_type = "t3.micro"

  metadata_options {
    http_endpoint = "enabled"
  }
}
```

### HCL Comments

HCL syntax supports comments:

```hcl
/*
This is a multi-line comment.
Multi-line comments aren't preferred.
Use multiple single-line comments instead.
*/
resource "aws_instance" "example" {
  # This is a single-line comment.
  ami           = "ami-123456"
  instance_type = "t3.micro"

  // This is also a single-line comment, but using `//` isn't preferred.
  metadata_options {
    http_endpoint = "enabled"
  }
}
```

## JSON Syntax

Terraform configuration written in JSON syntax is stored in files with the
`.tf.json` file extension.

JSON syntax is useful when programmatically reading or writing Terraform
configuration.

Since JSON syntax is far less common than HCL syntax, we won't spend too much
time on it. Instead, here's an example showing what a configuration using HCL
syntax would look like if converted to JSON syntax.

HCL syntax:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-123456"
  instance_type = "t3.micro"

  metadata_options {
    http_endpoint = "enabled"
  }
}
```

JSON syntax:

```json
{
  "resource": [
    {
      "aws_instance": [
        {
          "example": [
            {
              "ami": "ami-123456",
              "instance_type": "t3.micro",
              "metadata_options": [
                {
                  "http_endpoint": "enabled"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

### JSON Comments

JSON syntax supports a limited form of comments.

Create a JSON attribute `//` whose value is the text you wish to use as a
comment:

```json
{
  "//": "This is a comment.",
  "resource": [
    {
      "aws_instance": [
        {
          "example": [
            {
              "ami": "ami-123456",
              "instance_type": "t3.micro",
              "metadata_options": [
                {
                  "http_endpoint": "enabled"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

## Additional Resources

- [Terraform Language Syntax](https://www.terraform.io/language/syntax)
- [HCL Native Syntax Specification](https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md)
