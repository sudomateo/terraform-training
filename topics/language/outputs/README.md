# Outputs

Outputs let you expose information from your Terraform configuration. This
information can be read on the command line and used by other Terraform
configurations. Outputs are similar to function return values.

Outputs must be defined before they will be exposed.

## Defining Outputs

Outputs are defined inside output blocks.

```hcl
resource "aws_instance" "app" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
}

output "instance_id" {
  value = aws_instance.app.id
}
```

The output block expects one label; the output name (`instance_id`).

The output name is the name the output value will be exposed as.

## Arguments

Outputs accept the following arguments:

- `value` - The value to output.
- `description` - This specifies information about the output. type
  constraints.
- `sensitive` - Limits Terraform output when the output is used in
  configuration.

## Viewing Output Values

Output values can be viewed after Terraform configuration is applied.

```
Outputs:

instance_id = "i-034e7c122fdc83d05"
```
