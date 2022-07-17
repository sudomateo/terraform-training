# Locals

Locals let you assign a name to an expression. This allows you to use that name
instead of repeating a potentially complex expression multiple times. Locals
are similar to temporary variables within functions.

Locals must be defined before they can be used.

## Defining Locals

Locals are defined inside locals blocks.

```hcl
locals {
  ssh_info = "ssh ubuntu@${aws_instance.example.public_ip}"
}
```

The locals block expects no labels.

Within a locals block you can define multiple key value pairs. Each key is the
local name and each value is the local value.

## Accessing Local Values

Local values can be accessed using the syntax `local.NAME`.

```hcl
locals {
  ssh_info = "ssh ubuntu@${aws_instance.example.public_ip}"
}

resource "aws_instance" "example" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = var.instance_type
}

output "ssh_info" {
  value = local.ssh_info
}
```
