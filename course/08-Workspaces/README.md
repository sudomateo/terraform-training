# Workspaces

In this section, you will learn how to do the following:

- Describe what workspaces are and when to use them.
- How to update your configuration to avoid naming collisions.
- How to use workspaces to deploy a clone of your infrastructure.
- Learn about the alternatives to workspaces.

## What are Workspaces?

Workspaces are a way for Terraform to have multiple state files for the same
Terraform root module.

Put another way, workspaces are namespaces for state files for a given
Terraform configuration.

Workspaces are useful for deploying a clone of your infrastructure without
affecting your original infrastructure. However, before they can be used, there
are some requirements that must be met.

## Avoiding Infrastructure Collisions

Before workspaces can be used, your Terraform configuration must be able to be
applied without having naming collisions with existing resources.

Let's demonstrate what naming collisions are.

Apply your Terraform configuration to ensure we have existing infrastructure.

```
> terraform apply
module.todo.data.aws_vpc.default: Reading...
module.todo.aws_key_pair.app: Refreshing state... [id=todo]
module.todo.data.aws_ami.ubuntu: Reading...
module.todo.data.aws_ami.ubuntu: Read complete after 0s [id=ami-0f1bae6c3bedcc3b5]
module.todo.data.aws_vpc.default: Read complete after 0s [id=vpc-0bf582902425904f8]
module.todo.aws_security_group.app: Refreshing state... [id=sg-0df33022f41bd1f56]
module.todo.aws_security_group.db: Refreshing state... [id=sg-0920e615ac58adab2]
module.todo.aws_db_instance.db: Refreshing state... [id=todo20230420004303522800000001]
module.todo.aws_instance.app: Refreshing state... [id=i-0ee61f3b65e06e097]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so
no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

List the resources that are currently created.

```
> terraform state list
module.todo.data.aws_ami.ubuntu
module.todo.data.aws_vpc.default
module.todo.aws_db_instance.db
module.todo.aws_instance.app
module.todo.aws_key_pair.app
module.todo.aws_security_group.app
module.todo.aws_security_group.db
```

Create another root module with the same configuration and change into that
directory.

```
> mkdir foo
> cp main.tf foo
> cd foo
```

Update the copied configuration to remove its backend to ensure it's using a
separate state file.

```diff
--- main.tf	2023-04-19 20:55:48.333515759 -0400
+++ main.tf	2023-04-19 20:55:54.136568153 -0400
@@ -1,11 +1,4 @@
 terraform {
-  backend "s3" {
-    bucket         = "terraform-training20230420004138989500000001"
-    key            = "terraform/states/todo"
-    region         = "us-east-1"
-    dynamodb_table = "terraform-training"
-  }
-
   required_providers {
     aws = {
       source  = "hashicorp/aws"
```

Applying this copied configuration fails with the following error.

```
> terraform apply
...
module.todo.aws_key_pair.app: Creating...
module.todo.aws_security_group.app: Creating...
╷
│ Error: importing EC2 Key Pair (todo): InvalidKeyPair.Duplicate: The keypair already exists
│ 	status code: 400, request id: b8461100-6e2f-49ad-9d96-eafe26f75480
│ 
│   with module.todo.aws_key_pair.app,
│   on ../modules/todo/app.tf line 1, in resource "aws_key_pair" "app":
│    1: resource "aws_key_pair" "app" {
│ 
╵
╷
│ Error: creating Security Group (todo): InvalidGroup.Duplicate: The security group 'todo' already exists for VPC 'vpc-0bf582902425904f8'
│ 	status code: 400, request id: 40dddf55-d54a-4538-b1bf-6fcefaab3f81
│ 
│   with module.todo.aws_security_group.app,
│   on ../modules/todo/app.tf line 6, in resource "aws_security_group" "app":
│    6: resource "aws_security_group" "app" {
│ 
╵
```

Terraform requires that every resource have a unique identifier. However, some
reources use a configurable attribute as its unique identifier, causing a
collision when another resource attempts to use the same identifier.

Let's update the Terraform configuration to fix this.

```diff
--- modules/todo/app.tf	2023-04-19 01:53:47.678420197 -0400
+++ modules/todo/app.tf	2023-04-19 21:33:30.275065629 -0400
@@ -1,13 +1,17 @@
 resource "aws_key_pair" "app" {
-  key_name   = "todo"
-  public_key = var.ssh_public_key
+  key_name_prefix = "todo"
+  public_key      = var.ssh_public_key
 }
 
 resource "aws_security_group" "app" {
-  name        = "todo"
+  name_prefix = "todo"
   description = "Security group for todo application."
   vpc_id      = data.aws_vpc.default.id
 
+  lifecycle {
+    create_before_destroy = true
+  }
+
   ingress {
     description      = "SSH"
     from_port        = 22

--- modules/todo/db.tf	2023-04-19 01:53:47.678420197 -0400
+++ modules/todo/db.tf	2023-04-19 21:33:53.139271844 -0400
@@ -13,9 +13,13 @@
 }
 
 resource "aws_security_group" "db" {
-  name        = "db"
+  name_prefix = "db"
   description = "Security group for todo application."
 
+  lifecycle {
+    create_before_destroy = true
+  }
+
   ingress {
     description     = "Todo application database access."
     from_port       = var.db_port
```

Note the use of the `lifecycle` block to create the new security groups before
destroying the old ones. This is to ensure the old security groups are removed
from the instance and the databse and can safely be destroyed.

With these changes, let's apply the original root configuration again to update
it.

```
> cd ..
> terraform apply
...
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.todo.aws_instance.app: Destroying... [id=i-0f22be23445d07b49]
module.todo.aws_instance.app: Still destroying... [id=i-0f22be23445d07b49, 10s elapsed]
module.todo.aws_instance.app: Still destroying... [id=i-0f22be23445d07b49, 20s elapsed]
module.todo.aws_instance.app: Still destroying... [id=i-0f22be23445d07b49, 30s elapsed]
module.todo.aws_instance.app: Destruction complete after 40s
module.todo.aws_key_pair.app: Destroying... [id=todo]
module.todo.aws_security_group.app: Creating...
module.todo.aws_key_pair.app: Destruction complete after 0s
module.todo.aws_key_pair.app: Creating...
module.todo.aws_key_pair.app: Creation complete after 1s [id=todo20230420013539474200000002]
module.todo.aws_security_group.app: Creation complete after 3s [id=sg-0a21dbe0b62f94b3d]
module.todo.aws_security_group.db: Creating...
module.todo.aws_security_group.db: Creation complete after 2s [id=sg-0fd341bda031b9074]
module.todo.aws_db_instance.db: Modifying... [id=todo20230420012931869400000001]
module.todo.aws_db_instance.db: Still modifying... [id=todo20230420012931869400000001, 10s elapsed]
module.todo.aws_db_instance.db: Still modifying... [id=todo20230420012931869400000001, 20s elapsed]
module.todo.aws_db_instance.db: Still modifying... [id=todo20230420012931869400000001, 30s elapsed]
module.todo.aws_db_instance.db: Still modifying... [id=todo20230420012931869400000001, 40s elapsed]
module.todo.aws_db_instance.db: Still modifying... [id=todo20230420012931869400000001, 50s elapsed]
module.todo.aws_db_instance.db: Still modifying... [id=todo20230420012931869400000001, 1m0s elapsed]
module.todo.aws_db_instance.db: Still modifying... [id=todo20230420012931869400000001, 1m10s elapsed]
module.todo.aws_db_instance.db: Still modifying... [id=todo20230420012931869400000001, 1m20s elapsed]
module.todo.aws_db_instance.db: Still modifying... [id=todo20230420012931869400000001, 1m30s elapsed]
module.todo.aws_db_instance.db: Modifications complete after 1m31s [id=todo20230420012931869400000001]
module.todo.aws_instance.app: Creating...
module.todo.aws_instance.app: Still creating... [10s elapsed]
module.todo.aws_instance.app: Creation complete after 13s [id=i-0e2ef2fd02b5e75f4]
module.todo.aws_security_group.db (deposed object 331fcee4): Destroying... [id=sg-063361d07d9cd3c0c]
module.todo.aws_security_group.db: Destruction complete after 1s
module.todo.aws_security_group.app (deposed object 2ebbb31e): Destroying... [id=sg-07a5a55953ef41403]
module.todo.aws_security_group.app: Destruction complete after 1s

Apply complete! Resources: 4 added, 1 changed, 4 destroyed.
```

Applying the new configuration now succeeds without naming collisions!

```
> cd foo
> terraform apply
...
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.todo.aws_key_pair.app: Creating...
module.todo.aws_security_group.app: Creating...
module.todo.aws_key_pair.app: Creation complete after 0s [id=todo20230420013931137200000001]
module.todo.aws_security_group.app: Creation complete after 2s [id=sg-04ff34d44b0b7802f]
module.todo.aws_security_group.db: Creating...
module.todo.aws_security_group.db: Creation complete after 3s [id=sg-092c3dab39aeaad73]
module.todo.aws_db_instance.db: Creating...
module.todo.aws_db_instance.db: Still creating... [10s elapsed]
module.todo.aws_db_instance.db: Still creating... [20s elapsed]
module.todo.aws_db_instance.db: Still creating... [30s elapsed]
module.todo.aws_db_instance.db: Still creating... [40s elapsed]
module.todo.aws_db_instance.db: Still creating... [50s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m0s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m10s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m20s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m30s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m40s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m50s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m0s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m10s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m20s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m30s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m40s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m50s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m0s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m10s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m20s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m30s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m40s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m50s elapsed]
module.todo.aws_db_instance.db: Creation complete after 3m53s [id=todo20230420013935643700000004]
module.todo.aws_instance.app: Creating...
module.todo.aws_instance.app: Still creating... [10s elapsed]
module.todo.aws_instance.app: Creation complete after 13s [id=i-0b0f04da2d2042e28]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

Destroy the cloned infrastructure to prepare for the next section.

```
> terrafrom destroy
TODO
```

## Using Workspaces

Now we're ready to use workspaces!

The `terraform workspace` command has a few subcommands to interact with
workspaces.

```
> terraform workspace
Usage: terraform [global options] workspace

  new, list, show, select and delete Terraform workspaces.

Subcommands:
    delete    Delete a workspace
    list      List Workspaces
    new       Create a new workspace
    select    Select a workspace
    show      Show the name of the current workspace
```

Even if you're not explicitly using workspaces, Terraform still uses a `default`
workspace under the hood.

```
> terraform workspace show
default
```

This workspace has the managed infrastructure in its state. 

```
> terraform state list
module.todo.data.aws_ami.ubuntu
module.todo.data.aws_vpc.default
module.todo.aws_db_instance.db
module.todo.aws_instance.app
module.todo.aws_key_pair.app
module.todo.aws_security_group.app
module.todo.aws_security_group.db
```

Let's create and switch to a new workspace.

```
> terraform workspace new foo
Created and switched to workspace "foo"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
```

You can list all the workspaces. The currently selected workspace will have a
`*` next to it.

```
> terraform workspace list
  default
* foo
```

This new workspace does not have an anything in its state.

```
> terraform state list
```

Let's apply our configuration in this new workspace.

```
> terraform apply
Do you want to perform these actions in workspace "foo"?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.todo.aws_key_pair.app: Creating...
module.todo.aws_security_group.app: Creating...
module.todo.aws_key_pair.app: Creation complete after 1s [id=todo20230420023307356500000001]
module.todo.aws_security_group.app: Creation complete after 3s [id=sg-0c9cf8c8d2c9c497a]
module.todo.aws_security_group.db: Creating...
module.todo.aws_security_group.db: Creation complete after 2s [id=sg-050424b16c6151f58]
module.todo.aws_db_instance.db: Creating...
module.todo.aws_db_instance.db: Still creating... [10s elapsed]
module.todo.aws_db_instance.db: Still creating... [20s elapsed]
module.todo.aws_db_instance.db: Still creating... [30s elapsed]
module.todo.aws_db_instance.db: Still creating... [40s elapsed]
module.todo.aws_db_instance.db: Still creating... [50s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m0s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m10s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m20s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m30s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m40s elapsed]
module.todo.aws_db_instance.db: Still creating... [1m50s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m0s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m10s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m20s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m30s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m40s elapsed]
module.todo.aws_db_instance.db: Still creating... [2m50s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m0s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m10s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m20s elapsed]
module.todo.aws_db_instance.db: Still creating... [3m30s elapsed]
module.todo.aws_db_instance.db: Creation complete after 3m33s [id=todo20230420023311880700000004]
module.todo.aws_instance.app: Creating...
module.todo.aws_instance.app: Still creating... [10s elapsed]
module.todo.aws_instance.app: Creation complete after 14s [id=i-004ff107a8b8935e2]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

Now we have infrastructure in our new workspace's state.

```
> terraform state list
module.todo.data.aws_ami.ubuntu
module.todo.data.aws_vpc.default
module.todo.aws_db_instance.db
module.todo.aws_instance.app
module.todo.aws_key_pair.app
module.todo.aws_security_group.app
module.todo.aws_security_group.db
```

Once we're done with it, we can destroy the infrastructure.

```
> terraform destroy
Do you really want to destroy all resources in workspace "foo"?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

module.todo.aws_instance.app: Destroying... [id=i-004ff107a8b8935e2]
module.todo.aws_instance.app: Still destroying... [id=i-004ff107a8b8935e2, 10s elapsed]
module.todo.aws_instance.app: Still destroying... [id=i-004ff107a8b8935e2, 20s elapsed]
module.todo.aws_instance.app: Still destroying... [id=i-004ff107a8b8935e2, 30s elapsed]
module.todo.aws_instance.app: Destruction complete after 40s
module.todo.aws_key_pair.app: Destroying... [id=todo20230420023307356500000001]
module.todo.aws_db_instance.db: Destroying... [id=todo20230420023311880700000004]
module.todo.aws_key_pair.app: Destruction complete after 0s
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 10s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 20s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 30s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 40s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 50s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 1m0s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 1m10s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 1m20s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 1m30s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 1m40s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 1m50s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 2m0s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 2m10s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 2m20s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 2m30s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 2m40s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 2m50s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 3m0s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 3m10s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 3m20s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 3m30s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 3m40s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 3m50s elapsed]
module.todo.aws_db_instance.db: Still destroying... [id=todo20230420023311880700000004, 4m0s elapsed]
module.todo.aws_db_instance.db: Destruction complete after 4m3s
module.todo.aws_security_group.db: Destroying... [id=sg-050424b16c6151f58]
module.todo.aws_security_group.db: Destruction complete after 1s
module.todo.aws_security_group.app: Destroying... [id=sg-0c9cf8c8d2c9c497a]
module.todo.aws_security_group.app: Destruction complete after 1s

Destroy complete! Resources: 5 destroyed.
```

Let's switch back to the default workspace.

```
> terraform workspace select default
Switched to workspace "default".
```

Now we can delete the other workspace.

```
> terraform workspace select default
Switched to workspace "default".
```

## Alternatives to Workspaces

Workspaces are a great choice to create ephemeral environments when it's not
feasible to create multiple backends. However, workspaces are a bit tricky to
use due to their hidden nature and need to shared the same configuration.

Instead of workspaces, the recommended approach is to create re-usable modules
that are called by different root modules that each use their own state backend.
This way, the modules can be versioned to create a boundary for introducing
breaking changes.
