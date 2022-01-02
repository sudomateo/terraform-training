# Terraform in Automation

In this section, you will learn how to do the following:

- Verify that Terraform configuration is formatted and syntactically correct.
- Integrate Terraform into a CI/CD workflow.
- How to configure Terraform CLI itself.
- Use custom providers to interact with custom CRUD APIs.
- How to debug Terraform when errors occur.
- Tune Terraform to be more performant with large configuration.

## Verifying Terraform Configuration

Terraform provides subcommands that you can use to verify that your
configuration meets certain standards.

The first command is `terraform fmt`, which takes a Terraform configuration and
formats it to a standardized format.

Given this improperly formatted configuration.

```hcl
terraform {
# Partial backend configuration.
backend "s3" {}

required_providers {
aws = {
source  = "hashicorp/aws"
version = "~> 4.0"
}
}
}

# Configured via environment variables.
provider "aws" {}

resource "aws_key_pair" "sudomateo" {
key_name_prefix = "sudomateo"
public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
}

module "sudomateo_vm" {
source = "github.com/sudomateo/terraform-aws-terraform-training-vm?ref=main"

for_each = {
foo = {
ingress_rules = [
{
description = "SSH"
from_port   = 22
to_port     = 22
protocol    = "tcp"
},
]
}
}

name          = each.key
key_name      = aws_key_pair.sudomateo.key_name
ingress_rules = each.value.ingress_rules
}
```

Running `terraform fmt` will format the configuration. Any files that were
formatted will be printed to the screen.

```
> terraform fmt
main.tf
```

The configuration is now formatted.

```hcl
terraform {
  # Partial backend configuration.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configured via environment variables.
provider "aws" {}

resource "aws_key_pair" "sudomateo" {
  key_name_prefix = "sudomateo"
  public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
}

module "sudomateo_vm" {
  source = "github.com/sudomateo/terraform-aws-terraform-training-vm?ref=main"

  for_each = {
    foo = {
      ingress_rules = [
        {
          description = "SSH"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
        },
      ]
    }
  }

  name          = each.key
  key_name      = aws_key_pair.sudomateo.key_name
  ingress_rules = each.value.ingress_rules
}
```

If you just want to see what files need formatting, you can use the `-check`
option.

```
> terraform fmt -check
main.tf
```

You can also add `-diff` to get a diff view of what needs to change to be
formatted.

```diff
> terraform fmt -diff -check
main.tf
--- old/main.tf
+++ new/main.tf
@@ -1,40 +1,40 @@
 terraform {
-# Partial backend configuration.
-backend "s3" {}
+  # Partial backend configuration.
+  backend "s3" {}
 
-required_providers {
-aws = {
-source  = "hashicorp/aws"
-version = "~> 4.0"
-}
-}
+  required_providers {
+    aws = {
+      source  = "hashicorp/aws"
+      version = "~> 4.0"
+    }
+  }
 }
 
 # Configured via environment variables.
 provider "aws" {}
 
 resource "aws_key_pair" "sudomateo" {
-key_name_prefix = "sudomateo"
-public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
+  key_name_prefix = "sudomateo"
+  public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETEma9o59PQm3venxMkocCM8mifE0hspFm5XsYeccw8"
 }
 
 module "sudomateo_vm" {
-source = "github.com/sudomateo/terraform-aws-terraform-training-vm?ref=main"
-
-for_each = {
-foo = {
-ingress_rules = [
-{
-description = "SSH"
-from_port   = 22
-to_port     = 22
-protocol    = "tcp"
-},
-]
-}
-}
+  source = "github.com/sudomateo/terraform-aws-terraform-training-vm?ref=main"
 
-name          = each.key
-key_name      = aws_key_pair.sudomateo.key_name
-ingress_rules = each.value.ingress_rules
+  for_each = {
+    foo = {
+      ingress_rules = [
+        {
+          description = "SSH"
+          from_port   = 22
+          to_port     = 22
+          protocol    = "tcp"
+        },
+      ]
+    }
+  }
+
+  name          = each.key
+  key_name      = aws_key_pair.sudomateo.key_name
+  ingress_rules = each.value.ingress_rules
 }
```

Terraform also provides a way to validate that your configuration is
syntactically correct, `terraform validate`.

```
> terraform validate
╷
│ Error: Module not installed
│ 
│   on main.tf line 21:
│   21: module "sudomateo_vm" {
│ 
│ This module is not yet installed. Run "terraform init" to install all modules required by this
│ configuration.
╵
```

The `terraform validate` command requires your configuration to be initialized.

```
> terraform init
...
Terraform has been successfully initialized!

> terraform validate
Success! The configuration is valid.
```

Let's introduce an error into our configuration.

```diff
--- main.tf	2023-04-22 15:24:43.630097182 -0400
+++ main.tf	2023-04-22 15:24:22.894889549 -0400
@@ -21,6 +21,8 @@
 module "sudomateo_vm" {
   source = "github.com/sudomateo/terraform-aws-terraform-training-vm?ref=main"
 
+  error = "error"
+
   for_each = {
     foo = {
       ingress_rules = [
```

The validation now fails.

```
> terraform validate
╷
│ Error: Unsupported argument
│ 
│   on main.tf line 24, in module "sudomateo_vm":
│   24:   error = "error"
│ 
│ An argument named "error" is not expected here.
╵
```

You can list all of the providers required by your Terraform configuration using
`terraform providers`. This also requires the configuration to be initialized.

```
> terraform providers

Providers required by configuration:
.
├── provider[registry.terraform.io/hashicorp/aws] ~> 4.0
└── module.sudomateo_vm
    └── provider[registry.terraform.io/hashicorp/aws] ~> 4.0
```

After Terraform initializes its configuration, it creates a
`.terraform.lock.hcl` file that records the hashes of the installed plugin.

```hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "4.64.0"
  constraints = "~> 4.0"
  hashes = [
    "h1:4xXf+eZtKPiRyjle7HUPaVzF3h/6S8seNEIIbWlDbuk=",
    "zh:092614f767995140cf444cad1a97fb569885db16cb1c1dc9ee56e801232bac29",
    "zh:142e262fbb162c8a86493cfab4aadaf96a8572f1a3a6be444d465a4aee377dba",
    "zh:1c58c8cb9934dc98a2dd9dc48a8a3d94a14c2c3f2bc0136410a9344938d4ecfb",
    "zh:36efdf30cd52b92668cf6f912538c6e176b1a140a00e63ee0f753b85878c8b53",
    "zh:4c631e367fd69692b57f85564de561733380e9674e146d3a7725b781ec5db944",
    "zh:57ace91cb022ec944ad3af9272b78f48e7f71e9d1bf113ca56c6ce8deb4341fe",
    "zh:7fc9581b530ebf28fda80c62c20c6fbbb936a878c24872349eb107b7f198e64c",
    "zh:8280cd8f04c31af83f3e74f07704b258fbaa8bf1d70679d5ea2f0cbda2571de2",
    "zh:8e6217a9443b651d4349d75bdc37af9298970d854bf515d8c305919b193e4a38",
    "zh:9b12af85486a96aedd8d7984b0ff811a4b42e3d88dad1a3fb4c0b580d04fa425",
    "zh:9c62bc4a9034a6caf15b8863da6f5a621b947d5fca161b4bd2f2e8e78eec8e3b",
    "zh:9d0a45cd4a031d19ee14c0a15f25df6359dcd342ccf4e2ee4751b3ee496edb57",
    "zh:ab47f4e300c46dc1757e2b8d8d749f34f044f219479106a00bf40572091a8999",
    "zh:b55119290497dda96ab9ba3dca00d648808dc99d18960ad8aa875775bfaf95db",
    "zh:df513941e6979f557edcac28d84bd91af9786104b0deba45b3b259a5ad215897",
  ]
}
```

This file is used by future `terraform init` operations to ensure the plugin has
not been modified. If it was modified then the next `terraform init` will
replace it with a fresh copy. If you want to check if the providers have been
modified without replacing them with a fresh copy, use `terraform providers`.

```
> .terraform/providers/registry.terraform.io/hashicorp/aws/4.64.0/linux_amd64/terraform-provider-aws_v4.64.0_x5
> terraform providers
╷
│ Error: Required plugins are not installed
│
│ The installed provider plugins are not consistent with the packages selected in the dependency lock
│ file:
│   - registry.terraform.io/hashicorp/aws: the cached package for registry.terraform.io/hashicorp/aws 4.64.0 (in .terraform/providers) does not match any of the checksums recorded in the dependency lock file
│
│ Terraform uses external plugins to integrate with a variety of different infrastructure services. To
│ download the plugins required for this configuration, run:
│   terraform init
╵
```

## Running Terraform in CI/CD

Terraform can be run as a part of your CI/CD workflows.

At a minimum, it is recommended to configure CI/CD to run `terraform fmt` and
`terraform validate` on every push. This can be accomplished with the following
GitHub Actions workflow.

```yaml
---
name: Terraform Training

on:
  push:
env:
  TF_IN_AUTOMATION: 1

jobs:
  format:
    name: Format
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Install Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.4.5
      - name: Check formatting
        run: terraform fmt -check

  validate:
    name: Validate
    needs: [format]
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Install Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.4.5
      - name: Initialize configuration
        run: terraform init -input=false -backend=false
      - name: Validate configuration
        run: terraform validate
```

It's also a good practice to generate a plan to see what would change and only
apply the plan on merge to the default branch.

```yaml
  plan-apply:
    name: Plan & Apply
    needs: [validate]
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY_ID: ${{ vars.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: ${{ vars.AWS_REGION }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Install Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.4.5
      - name: Initialize configuration
        run: |
          terraform init -input=false \
            -backend-config="bucket=${{ vars.S3_BACKEND_BUCKET }}" \
            -backend-config="key=${{ vars.S3_BACKEND_KEY }}" \
            -backend-config="dynamodb_table=${{ vars.S3_BACKEND_DYNAMDB_TABLE }}"
      - name: Plan
        run: terraform plan -out plan.tfplan -input=false
      - name: Apply
        if: ${{ github.ref_name == 'main' }}
        run: terraform apply -input=false plan.tfplan
```

Running Terraform in CI/CD is a great way to collaborate on configuration
without worrying about sharing credentials or state access.

## Terraform CLI Configuration

Terraform itself can be configured via environment variables or through a
configuration file.

The default location for the Terraform CLI configuration file is
`%APPDATA%\terraform.rc` on Windows and `~/.terraformrc` on Linux and macOS.

While many of the settings without are rarely used day-to-day, there are two
settings worth noting.

The first is the plugin cache directory. When you initialize a Terraform
configuration, Terraform downloads the resulting plugins into a `.terraform`
directory.

```
> terraform init

Initializing the backend...
Initializing modules...
Downloading git::https://github.com/sudomateo/terraform-aws-terraform-training-vm.git?ref=main for sudomateo_vm...
- sudomateo_vm in .terraform/modules/sudomateo_vm

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v4.64.0...
- Installed hashicorp/aws v4.64.0 (signed by HashiCorp)

Terraform has been successfully initialized!

> tree -a .terraform/providers
.terraform/providers
└── registry.terraform.io
    └── hashicorp
        └── aws
            └── 4.64.0
                └── linux_amd64
                    └── terraform-provider-aws_v4.64.0_x5

6 directories, 1 file
```

When you initialize multiple configurations across multiple directories
Terraform will download plugins in each of those directories, creating
duplicates.

```
> mkdir -p foo && cp main.tf foo/main.tf && terraform -chdir=foo init
> mkdir -p bar && cp main.tf bar/main.tf && terraform -chdir=bar init
> tree -a foo/.terraform/providers bar/.terraform/providers
foo/.terraform/providers
└── registry.terraform.io
    └── hashicorp
        └── aws
            └── 4.64.0
                └── linux_amd64
                    └── terraform-provider-aws_v4.64.0_x5
bar/.terraform/providers
└── registry.terraform.io
    └── hashicorp
        └── aws
            └── 4.64.0
                └── linux_amd64
                    └── terraform-provider-aws_v4.64.0_x5

12 directories, 2 files
```

To fix this duplication, set a `plugin_cache_dir` within `~/.terraformrc`.

```hcl
plugin_cache_dir = "${HOME}/.terraform.d/plugin-cache"
```

Now, plugins will be downloaded to the cache location, saving disk space.

```
> mkdir -p ~/.terraform.d/plugin-cache
> rm -rf ~/.terraform.d/plugin-cache/*
> rm -rf foo/.terraform bar/.terraform
> terraform -chdir=foo init
> terraform -chdir=bar init
> tree -a foo/.terraform/providers bar/.terraform/providers
foo/.terraform/providers
└── registry.terraform.io
    └── hashicorp
        └── aws
            └── 4.64.0
                └── linux_amd64 -> /home/sudomateo/.terraform.d/plugin-cache/registry.terraform.io/hashicorp/aws/4.64.0/linux_amd64
bar/.terraform/providers
└── registry.terraform.io
    └── hashicorp
        └── aws
            └── 4.64.0
                └── linux_amd64 -> /home/sudomateo/.terraform.d/plugin-cache/registry.terraform.io/hashicorp/aws/4.64.0/linux_amd64

12 directories, 0 files
```

Using this cache directory can be useful for a long running CI/CD runner that
executes Terraform commands.

The other configuration that's worth noting is the `provider_installaion`
configuration. With it, Terraform will use providers from the filesystem mirror
assuming they follow a specific layout.

```hcl
plugin_cache_dir = "${HOME}/.terraform.d/plugin-cache"

provider_installation {
  filesystem_mirror {
    path = "/tmp/terraform/providers"
  }
  direct {}
}
```

To generate such a layout, use `terraform providers mirror`.

```
> terraform providers mirror /tmp/terraform/providers
- Mirroring hashicorp/aws...
  - Selected v4.64.0 to match dependency lock file
  - Downloading package for linux_amd64...
  - Package authenticated: signed by HashiCorp
```

Now your layout matches what Terraform expects.

```
> tree -a /tmp/terraform/providers
/tmp/terraform/providers
└── registry.terraform.io
    └── hashicorp
        └── aws
            ├── 4.64.0.json
            ├── index.json
            └── terraform-provider-aws_4.64.0_linux_amd64.zip

4 directories, 3 files
```

A fresh `terraform init` shows that we are pulling the package directly from the
fileystem mirror (unauthenticated).

```
> rm -rf .terraform
> rm -rf ~/.terraform.d/plugin-cache/*
> terraform init

Initializing the backend...
Initializing modules...
Downloading git::https://github.com/sudomateo/terraform-aws-terraform-training-vm.git?ref=main for sudomateo_vm...
- sudomateo_vm in .terraform/modules/sudomateo_vm

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v4.64.0...
- Installed hashicorp/aws v4.64.0 (unauthenticated)

Terraform has been successfully initialized!
```

In addition to a CLI configuration file, Terraform supports receiving
configuration via environment variables.

We could set the cache dirctory using an environment variable.

```
> rm -rf ~/.terraformrc
> rm -rf .terraform
> TF_PLUGIN_CACHE_DIR=~/.terraform.d/plugin-cache terraform init

Initializing the backend...
Initializing modules...
Downloading git::https://github.com/sudomateo/terraform-aws-terraform-training-vm.git?ref=main for sudomateo_vm...
- sudomateo_vm in .terraform/modules/sudomateo_vm

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using hashicorp/aws v4.64.0 from the shared cache directory

Terraform has been successfully initialized!
```

## Using Custom Providers

Let's use a custom provider to interact with our todo application.

Clone the https://github.com/sudomateo/terraform-provider-todo repository.

```
> git clone git@github.com:sudomateo/terraform-provider-todo.git
```

Change into the directory and build the provider.

```
> go build -o /tmp/terraform-provider-todo_1.0.0
```

Place the provider into a new Terraform configuration directory.

```
> mkdir todo && cd todo
> mkdir -p terraform.d/plugins/sudomateo.dev/sudomateo/todo/1.0.0/linux_amd64
> cp /tmp/terraform-provider-todo_1.0.0 terraform.d/plugins/sudomateo.dev/sudomateo/todo/1.0.0/linux_amd64
```

Deploy the todo application if you don't have it deployed already and create a
todo using the web interface.

Create a `main.tf` with the following content.

```hcl
terraform {
  required_providers {
    todo = {
      source = "sudomateo.dev/sudomateo/todo"
    }
  }
}

provider "todo" {
  host = "http://todo20230422022632771600000004-1147147699.us-east-1.elb.amazonaws.com:8888/"
}

data "todo_todos" "all" {}

output "todos" {
  value = data.todo_todos.all
}
```

Initialize and apply your configuration.

```
> terraform init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of sudomateo.dev/sudomateo/todo from the dependency lock file
- Installing sudomateo.dev/sudomateo/todo v1.0.0...
- Installed sudomateo.dev/sudomateo/todo v1.0.0 (unauthenticated)

Terraform has been successfully initialized!

> terraform apply
...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

todos = {
  "id" = "todos_id_placeholder"
  "todos" = tolist([
    {
      "completed" = false
      "id" = "f1aa5ef5-dfa8-47a8-a413-6801d098bbc8"
      "priority" = "high"
      "text" = "Complete the Terraform training material."
      "time_created" = "2023-04-22 02:45:20.580342 +0000 UTC"
      "time_updated" = "2023-04-22 02:45:20.580342 +0000 UTC"
    },
  ])
}
```

## Debugging Terraform

Troubleshooting Terraform can be a daunting task if you're not familiar with
networking, infrastructure, and a bit of code.

That being said, when more information is needed from Terraform you have a few
options.

First, you can use the `TF_LOG` environment variable to increase the verbosity
of Terraform logs.

```
> TF_LOG=TRACE terraform init
2023-04-21T22:51:04.534-0400 [INFO]  Terraform version: 1.4.5
2023-04-21T22:51:04.534-0400 [DEBUG] using github.com/hashicorp/go-tfe v1.18.0
2023-04-21T22:51:04.534-0400 [DEBUG] using github.com/hashicorp/hcl/v2 v2.16.2
2023-04-21T22:51:04.534-0400 [DEBUG] using github.com/hashicorp/terraform-config-inspect v0.0.0-20210209133302-4fd17a0faac2
2023-04-21T22:51:04.534-0400 [DEBUG] using github.com/hashicorp/terraform-svchost v0.1.0
2023-04-21T22:51:04.534-0400 [DEBUG] using github.com/zclconf/go-cty v1.12.1
2023-04-21T22:51:04.534-0400 [INFO]  Go runtime version: go1.19.6
2023-04-21T22:51:04.534-0400 [INFO]  CLI args: []string{"terraform", "init"}
2023-04-21T22:51:04.534-0400 [TRACE] Stdout is a terminal of width 105
2023-04-21T22:51:04.534-0400 [TRACE] Stderr is a terminal of width 105
2023-04-21T22:51:04.534-0400 [TRACE] Stdin is a terminal
2023-04-21T22:51:04.534-0400 [DEBUG] Attempting to open CLI config file: /home/sudomateo/.terraformrc
2023-04-21T22:51:04.534-0400 [DEBUG] File doesn't exist, but doesn't need to. Ignoring.
2023-04-21T22:51:04.534-0400 [DEBUG] checking for credentials in "/home/sudomateo/.terraform.d/plugins"
2023-04-21T22:51:04.534-0400 [DEBUG] will search for provider plugins in terraform.d/plugins
2023-04-21T22:51:04.534-0400 [TRACE] getproviders.SearchLocalDirectory: found sudomateo.dev/sudomateo/todo v1.0.0 for linux_amd64 at terraform.d/plugins/sudomateo.dev/sudomateo/todo/1.0.0/linux_amd64
2023-04-21T22:51:04.534-0400 [DEBUG] will search for provider plugins in /home/sudomateo/.terraform.d/plugins
2023-04-21T22:51:04.535-0400 [DEBUG] ignoring non-existing provider search directory /home/sudomateo/.local/share/terraform/plugins
2023-04-21T22:51:04.535-0400 [DEBUG] ignoring non-existing provider search directory /home/sudomateo/.local/share/flatpak/exports/share/terraform/plugins
2023-04-21T22:51:04.535-0400 [DEBUG] ignoring non-existing provider search directory /var/lib/flatpak/exports/share/terraform/plugins
2023-04-21T22:51:04.535-0400 [DEBUG] ignoring non-existing provider search directory /usr/local/share/terraform/plugins
2023-04-21T22:51:04.535-0400 [DEBUG] ignoring non-existing provider search directory /usr/share/terraform/plugins
2023-04-21T22:51:04.535-0400 [INFO]  CLI command args: []string{"init"}

Initializing the backend...
2023-04-21T22:51:04.536-0400 [TRACE] Meta.Backend: no config given or present on disk, so returning nil config
2023-04-21T22:51:04.536-0400 [TRACE] Meta.Backend: backend has not previously been initialized in this working directory
2023-04-21T22:51:04.536-0400 [DEBUG] New state was assigned lineage "a169107f-a070-33d1-3d11-bafaa80870a3"
2023-04-21T22:51:04.536-0400 [TRACE] Meta.Backend: using default local state only (no backend configuration, and no existing initialized backend)
2023-04-21T22:51:04.536-0400 [TRACE] Meta.Backend: instantiated backend of type <nil>
2023-04-21T22:51:04.536-0400 [TRACE] providercache.fillMetaCache: scanning directory .terraform/providers
2023-04-21T22:51:04.537-0400 [TRACE] getproviders.SearchLocalDirectory: found sudomateo.dev/sudomateo/todo v1.0.0 for linux_amd64 at .terraform/providers/sudomateo.dev/sudomateo/todo/1.0.0/linux_amd64
2023-04-21T22:51:04.537-0400 [TRACE] providercache.fillMetaCache: including .terraform/providers/sudomateo.dev/sudomateo/todo/1.0.0/linux_amd64 as a candidate package for sudomateo.dev/sudomateo/todo 1.0.0
2023-04-21T22:51:04.570-0400 [DEBUG] checking for provisioner in "."
2023-04-21T22:51:04.570-0400 [DEBUG] checking for provisioner in "/home/sudomateo/.local/bin"
2023-04-21T22:51:04.570-0400 [DEBUG] checking for provisioner in "/home/sudomateo/.terraform.d/plugins"
2023-04-21T22:51:04.570-0400 [TRACE] Meta.Backend: backend <nil> does not support operations, so wrapping it in a local backend
2023-04-21T22:51:04.570-0400 [TRACE] backend/local: state manager for workspace "default" will:
 - read initial snapshot from terraform.tfstate
 - write new snapshots to terraform.tfstate
 - create any backup at terraform.tfstate.backup
2023-04-21T22:51:04.571-0400 [TRACE] statemgr.Filesystem: reading initial snapshot from terraform.tfstate
2023-04-21T22:51:04.571-0400 [TRACE] statemgr.Filesystem: read snapshot with lineage "f93708c2-93b4-6ab3-a1c6-4e3aab2de20f" serial 2

Initializing provider plugins...
- Reusing previous version of sudomateo.dev/sudomateo/todo from the dependency lock file
2023-04-21T22:51:04.571-0400 [TRACE] providercache.fillMetaCache: scanning directory .terraform/providers
2023-04-21T22:51:04.571-0400 [TRACE] getproviders.SearchLocalDirectory: found sudomateo.dev/sudomateo/todo v1.0.0 for linux_amd64 at .terraform/providers/sudomateo.dev/sudomateo/todo/1.0.0/linux_amd64
2023-04-21T22:51:04.571-0400 [TRACE] providercache.fillMetaCache: including .terraform/providers/sudomateo.dev/sudomateo/todo/1.0.0/linux_amd64 as a candidate package for sudomateo.dev/sudomateo/todo 1.0.0
- Using previously-installed sudomateo.dev/sudomateo/todo v1.0.0

Terraform has been successfully initialized!
```

While there are levels other than `TRACE`, many plugins still only recognize two
levels; unset and `TRACE`.

## Tuning Terraform

You can tune your Terraform plans and applies to be more performant once you
understand a bit more about your workflows.

To illustrate, let's create a configuration.

```hcl
terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

data "external" "foo" {
  count   = 100
  program = ["bash", "-c", "${path.module}/foo.sh"]
  query = {
    tag = "foo-${count.index + 1}"
  }
}

resource "null_resource" "foo" {
  count = 100
  triggers = {
    image = data.external.foo[count.index].result.image
  }
}
```

We'll also create the corresponding `foo.sh`.

```sh
#!/bin/bash

read input

tag="$(echo ${input} | jq -r '.tag')"

# Simulate an API request that takes long to respond.
sleep 2

echo "{\"image\": \"ghcr.io/sudomateo/todo:${tag}\"}"
```

It takes Terraform around 20 seconds to plan this configuration.

```
> time terraform plan
real	0m20.749s
user	0m1.104s
sys		0m1.825s
```

This is because Terraform operations on 10 concurrent resources by default.

We can change that number using the `-parallelism` argument.

Now that we doubled the parallelism, we halved the total time of the plan
operation.

```
> time terraform plan -parallelism=20
real	0m10.692s
user	0m1.202s
sys		0m1.704s
```

We can increase this to 100 to really drop the plan time.

```
> time terraform plan -parallelism=100
real	0m2.932s
user	0m0.984s
sys		0m2.240s
```

If the data sources did not change frequently, we could choose to skip the
refresh operation entirely.

```
> terraform plan -refresh=false
```

We could also choose to target specific resources during the plan or apply.

```
> terraform apply -target null_resource.foo[0]
```
