# State Backends 

In this section, you will learn how to do the following:

- Describe how Terraform stores its state in a backend.
- Understand the differences between local and remote state backends.
- Describe the benefits of state locking.
- Configure remote state storage and locking.
- Migrate state between different backends.

## The Local Backend

By default, Terraform stores its state in a file located in the root module
directory.

```
> head terraform.tfstate
{
  "version": 4,
  "terraform_version": "1.4.5",
  "serial": 100,
  "lineage": "6f5b75d8-d920-5a7e-21bd-10d5a5ed1341",
  "outputs": {
    "app_url": {
      "value": "http://54.198.183.16:8080",
      "type": "string"
    },
```

Terraform requires access to this state file for most of its operations. Without
it, Terraform may perform undesirable actions.

```
> mv terraform.tfstate terraform.tfstate.bak

> terraform state list
No state file was found!

State management commands require a state file. Run this command
in a directory where Terraform has been run or use the -state flag
to point the command to a specific state location.
```

If you have previously applied a configuration and remove its state, Terraform
will want to create all the resources over again. Yikes!

```
> terraform plan
module.todo.data.aws_ami.ubuntu: Reading...
module.todo.data.aws_vpc.default: Reading...
module.todo.data.aws_ami.ubuntu: Read complete after 1s [id=ami-0f1bae6c3bedcc3b5]
module.todo.data.aws_vpc.default: Read complete after 1s [id=vpc-0bf582902425904f8]

...

Plan: 5 to add, 0 to change, 0 to destroy.
```

When multiple people are working on the same Terraform configuration, each
person must have the updated configuration and the updated state file in order
for the operations to stay in sync.

## Remote Backends

Terraform supports storing its state in a remote backend instead of a local
file. This allows different users and machines to interact with the same
Terraform state without needing to share access to the same local file.

Terraform supports the following remote backends:

- `remote` - Terraform Cloud/Enterprise
- `azurerm` - Azure Blob Storage
- `consul` - HashiCorp Consul
- `cos` - Tencent Cloud Object Storage
- `gcs` - Google Cloud Storage
- `http` - HTTP
- `kubernetes` - Kubernetes
- `oss` - Alibaba Cloud Object Storage Service
- `pg` - PostgreSQL
- `s3` - AWS S3

## Configuring Remote State Storage

A remote backend must be configured before Terraform will use it to store its
state.

We'll use the `s3` remote backend to store our state which requires an AWS S3
bucket.

Let's create a new `base/main.tf` with the following content.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {}

resource "aws_s3_bucket" "terraform_training" {
  bucket_prefix = "terraform-training"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_training" {
  bucket = aws_s3_bucket.terraform_training.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "terraform_training_bucket" {
  value = aws_s3_bucket.terraform_training.bucket
}
```

Applying this configuration will give us an AWS S3 bucket that we can use as our
remote backend.

```
> terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.terraform_training will be created
  + resource "aws_s3_bucket" "terraform_training" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = (known after apply)
      + bucket_domain_name          = (known after apply)
      + bucket_prefix               = "terraform-training"
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags_all                    = (known after apply)
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)
    }

  # aws_s3_bucket_versioning.terraform_training will be created
  + resource "aws_s3_bucket_versioning" "terraform_training" {
      + bucket = (known after apply)
      + id     = (known after apply)

      + versioning_configuration {
          + mfa_delete = (known after apply)
          + status     = "Enabled"
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + terraform_training_bucket = {
      + bucket_prefix = "terraform-training"
      + force_destroy = false
      + tags          = null
      + timeouts      = null
    }

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_s3_bucket.terraform_training: Creating...
aws_s3_bucket.terraform_training: Creation complete after 0s [id=terraform-training20230419044120594100000001]
aws_s3_bucket_versioning.terraform_training: Creating...
aws_s3_bucket_versioning.terraform_training: Creation complete after 2s [id=terraform-training20230419044120594100000001]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

terraform_training_bucket = "terraform-training20230419044120594100000001"
```

Let's update our application `main.tf` to use this new S3 bucket as a remote
backend.

```diff
--- main.tf	2023-04-19 00:55:26.097423042 -0400
+++ main.tf	2023-04-19 00:43:31.190270193 -0400
@@ -1,4 +1,9 @@
 terraform {
+  backend "s3" {
+    bucket = "terraform-training20230419044120594100000001"
+    key    = "todo"
+    region = "us-east-1"
+  }
+
   required_providers {
     aws = {
       source  = "hashicorp/aws"
```

With our backend changed, we need to initialize Terraform again. You'll notice
that doing so prompts you to copy your local state file up to the new remote
backend.

```
> terraform init

Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing modules...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v4.63.0

Terraform has been successfully initialized!
```

At this point, it is safe to archive your local `terraform.tfstate` file.

```
> mv terraform.tfstate terraform.tfstate.bak

> terraform state list
module.todo.data.aws_ami.ubuntu
module.todo.data.aws_vpc.default
module.todo.aws_db_instance.db
module.todo.aws_instance.app
module.todo.aws_key_pair.app
module.todo.aws_security_group.app
module.todo.aws_security_group.db
```

## State Locking

Remote backends are great but there's something that the local state file did
well that not all remote backends support. That's locking.

Terraform supports locking the state file so that only one Terraform process can
modify the state file at a given time.

Without locking, two Terraform processes can attempt to write to the state file
at the same time.

Let's see that in action by using the `null_resource` resource with a
provisioner.

Update the configuration like so.

```diff
--- main.tf	2023-04-19 01:09:39.974474264 -0400
+++ main.tf	2023-04-19 01:09:45.541519066 -0400
@@ -10,11 +10,21 @@
       source  = "hashicorp/aws"
       version = "~> 4.0"
     }
+    null = {
+      source  = "hashicorp/null"
+      version = "~> 3.0"
+    }
   }
 }
 
 provider "aws" {}
 
+resource "null_resource" "null" {
+  provisioner "local-exec" {
+    command = "sleep 60; echo FOO"
+  }
+}
+
 variable "ssh_public_key" {
   type = string
 }
```

Then, open two terminal windows. In the first window, apply your configuration.

```
> terraform apply
module.todo.data.aws_vpc.default: Reading...
module.todo.data.aws_ami.ubuntu: Reading...
module.todo.aws_key_pair.app: Refreshing state... [id=todo]
module.todo.data.aws_ami.ubuntu: Read complete after 0s [id=ami-0f1bae6c3bedcc3b5]
module.todo.data.aws_vpc.default: Read complete after 1s [id=vpc-0bf582902425904f8]
module.todo.aws_security_group.app: Refreshing state... [id=sg-01d9c1121beb7348b]
module.todo.aws_security_group.db: Refreshing state... [id=sg-0abc786d38205a9eb]
module.todo.aws_db_instance.db: Refreshing state... [id=todo20230418234534268000000001]
module.todo.aws_instance.app: Refreshing state... [id=i-05f294f2d89dbe880]

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # null_resource.null will be created
  + resource "null_resource" "null" {
      + id = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

null_resource.null: Creating...
null_resource.null: Provisioning with 'local-exec'...
null_resource.null (local-exec): Executing: ["/bin/sh" "-c" "sleep 60; echo FOO"]
null_resource.null: Still creating... [10s elapsed]
null_resource.null: Still creating... [20s elapsed]
null_resource.null: Still creating... [30s elapsed]
null_resource.null: Still creating... [40s elapsed]
null_resource.null: Still creating... [50s elapsed]
null_resource.null (local-exec): FOO
null_resource.null: Still creating... [1m0s elapsed]
null_resource.null: Creation complete after 1m0s [id=7180014025953205862]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

While the apply in the first window is running, update your configuration like
so.

```diff
--- main.tf	2023-04-19 01:14:43.914920518 -0400
+++ main.tf	2023-04-19 01:12:33.823873481 -0400
@@ -21,7 +21,7 @@
 
 resource "null_resource" "null" {
   provisioner "local-exec" {
-    command = "sleep 60; echo FOO"
+    command = "echo BAR"
   }
 }
```

Then apply your configuration in the second window.

```
> terraform apply
module.todo.aws_key_pair.app: Refreshing state... [id=todo]
module.todo.data.aws_vpc.default: Reading...
module.todo.data.aws_ami.ubuntu: Reading...
module.todo.data.aws_ami.ubuntu: Read complete after 1s [id=ami-0f1bae6c3bedcc3b5]
module.todo.data.aws_vpc.default: Read complete after 1s [id=vpc-0bf582902425904f8]
module.todo.aws_security_group.app: Refreshing state... [id=sg-01d9c1121beb7348b]
module.todo.aws_security_group.db: Refreshing state... [id=sg-0abc786d38205a9eb]
module.todo.aws_db_instance.db: Refreshing state... [id=todo20230418234534268000000001]
module.todo.aws_instance.app: Refreshing state... [id=i-05f294f2d89dbe880]

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # null_resource.null will be created
  + resource "null_resource" "null" {
      + id = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

null_resource.null: Creating...
null_resource.null: Provisioning with 'local-exec'...
null_resource.null (local-exec): Executing: ["/bin/sh" "-c" "echo BAR"]
null_resource.null (local-exec): BAR
null_resource.null: Creation complete after 0s [id=7975862535157275799]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Yikes! Terraform just performed two simultaneous apply operations on the same
state file.

It may not be obvious, but there's a difference in the output.

The apply in the first terminal window shows this.

```
null_resource.null (local-exec): Executing: ["/bin/sh" "-c" "sleep 60; echo FOO"]
null_resource.null: Still creating... [10s elapsed]
null_resource.null: Still creating... [20s elapsed]
null_resource.null: Still creating... [30s elapsed]
null_resource.null: Still creating... [40s elapsed]
null_resource.null: Still creating... [50s elapsed]
null_resource.null (local-exec): FOO
```

While the apply in the second terminal window shows this.

```
null_resource.null (local-exec): Executing: ["/bin/sh" "-c" "echo BAR"]
null_resource.null (local-exec): BAR
```

This is a race condition and data integrity issue. Whichever apply completes
last will make the most recent update to state.

## Configuring Remote State Locking

State locking must be configured before Terraform can lock state.

We'll update the `s3` remote backend to support locking which requires an AWS
DynamoDB table.

Let's update our `base/main.tf` to create a DynamoDB table.

```diff
--- main.tf	2023-04-19 01:26:56.212810029 -0400
+++ main.tf	2023-04-19 01:27:46.409209002 -0400
@@ -20,6 +20,22 @@
   }
 }
 
+resource "aws_dynamodb_table" "terraform_training" {
+  name           = "terraform-training"
+  read_capacity  = 20
+  write_capacity = 20
+  hash_key       = "LockID"
+
+  attribute {
+    name = "LockID"
+    type = "S"
+  }
+}
+
 output "terraform_training_bucket" {
   value = aws_s3_bucket.terraform_training.bucket
 }
+
+output "terraform_training_dynamodb_table" {
+  value = aws_dynamodb_table.terraform_training.id
+}
```

Apply the configuration to create the DynamoDB table.

```
> terraform apply
aws_s3_bucket.terraform_training: Refreshing state... [id=terraform-training20230419044120594100000001]
aws_s3_bucket_versioning.terraform_training: Refreshing state... [id=terraform-training20230419044120594100000001]

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_dynamodb_table.terraform_training will be created
  + resource "aws_dynamodb_table" "terraform_training" {
      + arn              = (known after apply)
      + billing_mode     = "PROVISIONED"
      + hash_key         = "LockID"
      + id               = (known after apply)
      + name             = "terraform-training"
      + read_capacity    = 20
      + stream_arn       = (known after apply)
      + stream_label     = (known after apply)
      + stream_view_type = (known after apply)
      + tags_all         = (known after apply)
      + write_capacity   = 20

      + attribute {
          + name = "LockID"
          + type = "S"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + terraform_training_dynamodb_table = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_dynamodb_table.terraform_training: Creating...
aws_dynamodb_table.terraform_training: Still creating... [10s elapsed]
aws_dynamodb_table.terraform_training: Creation complete after 13s [id=terraform-training]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

terraform_training_bucket = "terraform-training20230419044120594100000001"
terraform_training_dynamodb_table = "terraform-training"
```

Back in our application configuration, update the remote backend to use a
DynamoDB table.

```diff
--- main.tf	2023-04-19 01:29:54.720228874 -0400
+++ main.tf	2023-04-19 01:29:41.664125102 -0400
@@ -3,6 +3,7 @@
     bucket         = "terraform-training20230419044120594100000001"
     key            = "terraform/states/todo"
     region         = "us-east-1"
+    dynamodb_table = "terraform-training"
   }
 
   required_providers {
```

Initialize Terraform again to configure it to use the DynamoDB table for state
locking.

```
> terraform init

Initializing the backend...
Initializing modules...
╷
│ Error: Backend configuration changed
│ 
│ A change in the backend configuration has been detected, which may require migrating existing state.
│ 
│ If you wish to attempt automatic migration of the state, use "terraform init -migrate-state".
│ If you wish to store the current configuration with no changes to the state, use "terraform init
│ -reconfigure".
╵

> terraform init -migrate-state

Initializing the backend...
Backend configuration changed!

Terraform has detected that the configuration specified for the backend
has changed. Terraform will now check for existing state in the backends.


Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing modules...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Using previously-installed hashicorp/aws v4.63.0
- Using previously-installed hashicorp/null v3.2.1

Terraform has been successfully initialized!
```

Attempt to run two simultaneous apply operations again. This time you'll notice
the second apply operation fails to acquire a lock.

```
> terraform apply -replace null_resource.null
╷
│ Error: Error acquiring the state lock
│ 
│ Error message: ConditionalCheckFailedException: The conditional request failed
│ Lock Info:
│   ID:        3e4fb88a-2a9d-c227-9699-a24a0463b834
│   Path:      terraform-training20230419044120594100000001/terraform/states/todo
│   Operation: OperationTypeApply
│   Who:       sudomateo@vm-fedora
│   Version:   1.4.5
│   Created:   2023-04-19 05:32:17.887145171 +0000 UTC
│   Info:      
│ 
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
╵
```

## Migrating State Between Backends

Terraform support migrating state across backends. The safest way to do that is
to configure the new backend and running `terraform init`.

Let's migrate from the `s3` backend to the `pg` backend.

First, we'll spin up a PostgreSQL database server.

```
docker run --rm --name terraform-training-db --publish 5432:5432 --env POSTGRES_USER=terraform --env POSTGRES_PASSWORD=terraform postgres:14
```

Next, let's update our Terraform configuration.

```diff
--- main.tf	2023-04-19 01:37:29.799844716 -0400
+++ main.tf	2023-04-19 01:37:34.531882291 -0400
@@ -1,9 +1,6 @@
 terraform {
-  backend "s3" {
-    bucket         = "terraform-training20230419044120594100000001"
-    key            = "terraform/states/todo"
-    region         = "us-east-1"
-    dynamodb_table = "terraform-training"
+  backend "pg" {
+    conn_str = "postgres://terraform:terraform@localhost:5432/terraform?sslmode=disable"
   }
 
   required_providers {
```

Then, initialize Terraform to see an error on how you should proceed.

```
> terraform init

Initializing the backend...
Initializing modules...
╷
│ Error: Backend configuration changed
│ 
│ A change in the backend configuration has been detected, which may require migrating existing state.
│ 
│ If you wish to attempt automatic migration of the state, use "terraform init -migrate-state".
│ If you wish to store the current configuration with no changes to the state, use "terraform init
│ -reconfigure".
╵
```

Tell the Terraform initialization process to migrate your state.

```
> terraform init -migrate-state

Initializing the backend...
Terraform detected that the backend type changed from "s3" to "pg".

Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "s3" backend to the
  newly configured "pg" backend. No existing state was found in the newly
  configured "pg" backend. Do you want to copy this state to the new "pg"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "pg"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing modules...

Initializing provider plugins...
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/null v3.2.1
- Using previously-installed hashicorp/aws v4.63.0

Terraform has been successfully initialized!
```

You can connect to the database to see that the schema, table, and index were
successfully created.

```
> docker exec -it terraform-training-db psql -U terraform -c '\d terraform_remote_state.states;'
                       Table "terraform_remote_state.states"
 Column |  Type  | Collation | Nullable |                  Default                  
--------+--------+-----------+----------+-------------------------------------------
 id     | bigint |           | not null | nextval('global_states_id_seq'::regclass)
 name   | text   |           |          | 
 data   | text   |           |          | 
Indexes:
    "states_pkey" PRIMARY KEY, btree (id)
    "states_by_name" UNIQUE, btree (name)
    "states_name_key" UNIQUE CONSTRAINT, btree (name)
```

We can also see that there's 1 row in the database table.

```
> docker exec -it terraform-training-db psql -U terraform -c 'SELECT COUNT(*) FROM terraform_remote_state.states;'
 count 
-------
     1
(1 row)
```

Let's restore the `s3` backend.

```diff
--- main.tf	2023-04-19 01:55:35.797260005 -0400
+++ main.tf	2023-04-19 01:56:07.652507445 -0400
@@ -1,6 +1,9 @@
 terraform {
-  backend "pg" {
-    conn_str = "postgres://terraform:terraform@localhost:5432/terraform"
+  backend "s3" {
+    bucket         = "terraform-training20230419044120594100000001"
+    key            = "terraform/states/todo"
+    region         = "us-east-1"
+    dynamodb_table = "terraform-training"
   }
 
   required_providers {
```

We'll migrate back from the `pg` backend to the `s3` backend.

```
> terraform init -migrate-state

Initializing the backend...
Terraform detected that the backend type changed from "pg" to "s3".

Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "pg" backend to the
  newly configured "s3" backend. An existing non-empty state already exists in
  the new backend. The two states have been saved to temporary files that will be
  removed after responding to this query.
  
  Previous (type "pg"): /tmp/terraform1549560650/1-pg.tfstate
  New      (type "s3"): /tmp/terraform1549560650/2-s3.tfstate
  
  Do you want to overwrite the state in the new backend with the previous state?
  Enter "yes" to copy and "no" to start with the existing state in the newly
  configured "s3" backend.

  Enter a value: yes


Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing modules...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Using previously-installed hashicorp/aws v4.63.0
- Using previously-installed hashicorp/null v3.2.1

Terraform has been successfully initialized!
```

### Pulling and Pushing State Manually

You can retrieve the raw state file from a backend by using `terraform state
pull`.

```
> terraform state pull
{
  "version": 4,
  "terraform_version": "1.4.5",
  "serial": 1,
  "lineage": "13af4d7d-3af4-e67b-cfa1-dc2a244c5077",
  "outputs": {
    "app_url": {
      "value": "http://54.198.183.16:8080",
      "type": "string"
    },
    "ssh_info": {
      "value": "ssh -l ubuntu 54.198.183.16",
      "type": "string"
    }
  },
  "resources": [
    ...
  ],
  "check_results": null
}
```

You can save this to a file for manual edits.

```
> terraform state pull > state.tfstate
```

Let's update the serial of the pulled state.

```diff
--- state.tfstate	2023-04-19 01:48:52.829193460 -0400
+++ state.tfstate	2023-04-19 01:49:03.772274596 -0400
@@ -1,7 +1,7 @@
 {
   "version": 4,
   "terraform_version": "1.4.5",
-  "serial": 1,
+  "serial": 2,
   "lineage": "13af4d7d-3af4-e67b-cfa1-dc2a244c5077",
   "outputs": {
     "app_url": {
```

Now, we'll push the modified state to our backend.

```
> terraform state push state.tfstate
```

Be careful when manually modifying your state!
