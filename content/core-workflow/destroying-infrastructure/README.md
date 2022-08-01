# Destroying Infrastructure

Typically, most of the infrastructure managed by Terraform is long-lived
production infrastructure. However, you may use Terraform to spin up ephemeral
infrastructure that you wish to later destroy.

You can tell Terraform to destroy all of the infrastructure it manages.

```
terraform destroy
```

`terraform destroy` is just an alias for:

```
terraform apply -destroy
```

Like `terraform apply`, `terraform destroy` will execute a destroy plan and
prompt for confirmation before applying the destroy plan.

```
aws_instance.app: Refreshing state... [id=i-01498124dc55cc00e]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_instance.app will be destroyed
  - resource "aws_instance" "app" {
      - ami                                  = "ami-052efd3df9dad4825" -> null
      - id                                   = "i-01498124dc55cc00e" -> null
      ...
      - tags                                 = {
          - "Environment" = "Development"
          - "Name"        = "app"
        } -> null
      ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

## Speculative Destroy Plan

You can create a speculative destroy plan to see what resources Terraform would
destroy.

```
terraform plan -destroy
```
