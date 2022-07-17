# Variables

Variables let you pass information to your Terraform configuration without
modifying it. Variables are similar to function arguments.

Variables must be defined before they can be used.

## Defining Variables

Variables are defined inside variable blocks.

```hcl
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
```

The variable block expects one label; the variable name (`instance_type`).

The variable name serves as a unique identifier for a variable.

## Arguments

Variables accept the following arguments:

- `default` - A default value which then makes the variable optional.
- `type` - This argument specifies what types are accepted for the variable
  value.
- `description` - This specifies information about the variable.
- `validation` - A block to define validation rules, usually in addition to
  type constraints.
- `sensitive` - Limits Terraform output when the variable is used in
  configuration.
- `nullable` - Specify if the variable can be `null` within the module.

## Accessing Variable Values

Variable values can be accessed using the syntax `var.NAME`.

```hcl
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

resource "aws_instance" "app" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = var.instance_type
}
```
