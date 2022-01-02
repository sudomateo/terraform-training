# Terraform Cloud & Terraform Enterprise

In this section, you will learn how to do the following:

- Explain what Terraform Cloud & Terraform Enterprise are and why you'd want to
  use them.
- Connect your VCS repository to Terraform Cloud/Enterprise to execute VCS-driven Terraform runs.
- Connect your local Terraform configuration to Terraform Cloud/Enterprise to
  execute CLI-driven Terraform runs.
- Use the Terraform Cloud/Enterprise API to execute API-driven Terraform runs.
- Publish a module to the Private Module Registry.
- Describe the benefits of the paid features of Terraform Cloud/Enterprise.

## What is Terraform Cloud and Terraform Enterprise?

Terraform Cloud is a Software as a Service (SaaS) application that manages
Terraform runs and their state. It it aimed at teams that want a consistent,
reliable environment to execute Terraform runs without any of the overhead that
comes from managing your own CI/CD workflow.

Terraform Enterprise is the self-hosted version of Terraform Cloud that you can
purchase and run in your own data center or cloud account.

Terraform Cloud/Enterprise have a concept of workspaces. These workspaces are a
bit different than what we covered earlier. A Terraform Cloud/Enteprise
workspace is a representation of a root module configuration with its own
separate state file. That way, you can have multiple workspaces using the same
configuration, but with different state files, variables, etc.

## VCS-driven Runs

The most common way to interact with Terraform Cloud/Enterprise by storing your
configuration in VCS and linking it to a Terraform Cloud/Enterprise workspace.
That way, new commits to VCS will trigger runs in Terraform Cloud/Enterprise.

This section will be demonstrated live during the course. The high level process
is as follows.

1. Push your configuration to a VCS repository.
1. Configure VCS within Terraform Cloud/Enterprise.
1. Create a workspace in Terraform Cloud/Enteprise pointing to your VCS
   respository.
1. Add any necessary variables needed by the workspace.
1. Migrate existing state for your Terraform configuration to the workspace.
1. Push commits to the VCS repository to trigger runs in Terraform
   Cloud/Enterprise.

## CLI-driven Runs

You can also run Terraform directly from the CLI while storing your state in
Teraform Cloud/Enterprise.

To do that, add a `cloud` block to your configuration.

```diff
> diff -u /tmp/main.tf main.tf 
--- main.tf	2023-04-22 16:02:23.495676111 -0400
+++ main.tf	2023-04-22 16:17:53.556948409 -0400
@@ -1,4 +1,11 @@
 terraform {
+  cloud {
+    organization = "sudomateo"
+    workspaces {
+      name = "terraform-training-todo"
+    }
+  }
+
   required_providers {
     aws = {
       source  = "hashicorp/aws"
```

Log into Terraform Cloud/Enterprise.

```
> terraform login
Terraform will request an API token for app.terraform.io using your browser.

If login is successful, Terraform will store the token in plain text in
the following file for use by subsequent commands:
    /home/sudomateo/.terraform.d/credentials.tfrc.json

Do you want to proceed?
  Only 'yes' will be accepted to confirm.

  Enter a value: yes


---------------------------------------------------------------------------------

Terraform must now open a web browser to the tokens page for app.terraform.io.

If a browser does not open this automatically, open the following URL to proceed:
    https://app.terraform.io/app/settings/tokens?source=terraform-login


---------------------------------------------------------------------------------

Generate a token using your browser, and copy-paste it into this prompt.

Terraform will store the token in plain text in the following file
for use by subsequent commands:
    /home/sudomateo/.terraform.d/credentials.tfrc.json

Token for app.terraform.io:
  Enter a value: 


Retrieved token for user sudomateo


---------------------------------------------------------------------------------

                                          -                                
                                          -----                           -
                                          ---------                      --
                                          ---------  -                -----
                                           ---------  ------        -------
                                             -------  ---------  ----------
                                                ----  ---------- ----------
                                                  --  ---------- ----------
   Welcome to Terraform Cloud!                     -  ---------- -------
                                                      ---  ----- ---
   Documentation: terraform.io/docs/cloud             --------   -
                                                      ----------
                                                      ----------
                                                       ---------
                                                           -----
                                                               -


   New to TFC? Follow these steps to instantly apply an example configuration:

   $ git clone https://github.com/hashicorp/tfc-getting-started.git
   $ cd tfc-getting-started
   $ scripts/setup.sh
```

Then initialize your configuration to have Terraform reach out to Terraform
Cloud/Enterprise to create the desired workspace and migrate your existing
state, if any.

```
> terraform init

Initializing Terraform Cloud...
Do you wish to proceed?
  As part of migrating to Terraform Cloud, Terraform can optionally copy your
  current workspace state to the configured Terraform Cloud workspace.
  
  Answer "yes" to copy the latest state snapshot to the configured
  Terraform Cloud workspace.
  
  Answer "no" to ignore the existing state and just activate the configured
  Terraform Cloud workspace with its existing state, if any.
  
  Should Terraform migrate your existing state?

  Enter a value: yes

Initializing modules...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/random from the dependency lock file
- Using previously-installed hashicorp/aws v4.64.0
- Using previously-installed hashicorp/random v3.5.1

Terraform Cloud has been successfully initialized!
```

Planning this configuration will start a run in Terraform Cloud/Enterprise. The
run will fail since the Terraform Cloud/Enterprise workspace does not have the
necessary variables.

```
> terraform plan
Running plan in Terraform Cloud. Output will stream here. Pressing Ctrl-C
will stop streaming the logs, but will not stop the plan running remotely.

Preparing the remote plan...

To view this run in a browser, visit:
https://app.terraform.io/app/sudomateo/terraform-training-todo/runs/run-yE3Ey1ZuipWt9XyA

Waiting for the plan to start...

Terraform v1.4.5
on linux_amd64
Initializing plugins and modules...
╷
│ Error: configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found.
│ 
│ Please see https://registry.terraform.io/providers/hashicorp/aws
│ for more information about providing credentials.
│ 
│ AWS Error: failed to refresh cached credentials, no EC2 IMDS role found, operation error ec2imds: GetMetadata, request canceled, context deadline exceeded
│ 
│ 
│   with provider["registry.terraform.io/hashicorp/aws"],
│   on main.tf line 17, in provider "aws":
│   17: provider "aws" {}
│ 
╵
Operation failed: failed running terraform plan (exit 1)
```

Once the necessary variables are added on the workspace, the plan will succeed.

```
> terraform plan
Running plan in Terraform Cloud. Output will stream here. Pressing Ctrl-C
will stop streaming the logs, but will not stop the plan running remotely.

Preparing the remote plan...

To view this run in a browser, visit:
https://app.terraform.io/app/sudomateo/terraform-training-todo/runs/run-KSd6G7YeadfV428u

Waiting for the plan to start...

Terraform v1.4.5
on linux_amd64
Initializing plugins and modules...
module.todo.data.aws_vpc.default: Refreshing...
module.todo.aws_key_pair.app: Refreshing state... [id=todo20230422172337235700000001]
module.todo.data.aws_region.current: Refreshing...
module.todo.data.aws_ami.ubuntu: Refreshing...
module.todo.data.aws_region.current: Refresh complete after 0s [id=us-east-1]
module.todo.data.aws_ami.ubuntu: Refresh complete after 0s [id=ami-0b5df848226550db1]
module.todo.data.aws_vpc.default: Refresh complete after 0s [id=vpc-0bf582902425904f8]
module.todo.data.aws_subnets.default: Refreshing...
module.todo.aws_security_group.lb: Refreshing state... [id=sg-0aac5004e5800fa14]
module.todo.aws_lb_target_group.lb: Refreshing state... [id=arn:aws:elasticloadbalancing:us-east-1:371868434650:targetgroup/todo20230422165404959600000002/6a490cc18b2df4a1]
module.todo.data.aws_subnets.default: Refresh complete after 0s [id=us-east-1]
module.todo.aws_lb.lb: Refreshing state... [id=arn:aws:elasticloadbalancing:us-east-1:371868434650:loadbalancer/app/todo20230422165407178000000004/074cc50941db12ee]
module.todo.aws_security_group.app: Refreshing state... [id=sg-06bc37a365d18ed75]
module.todo.aws_security_group.db: Refreshing state... [id=sg-06d7f58b705613a9d]
module.todo.aws_lb_listener.lb: Refreshing state... [id=arn:aws:elasticloadbalancing:us-east-1:371868434650:listener/app/todo20230422165407178000000004/074cc50941db12ee/d2a58629fce2835c]
module.todo.aws_db_instance.db: Refreshing state... [id=todo20230422165411594100000007]
module.todo.aws_launch_template.app: Refreshing state... [id=lt-0747ede26832c3753]
module.todo.aws_autoscaling_group.app: Refreshing state... [id=todo2023042216573498430000000a]

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # module.todo.aws_lb_listener.lb will be updated in-place
  ~ resource "aws_lb_listener" "lb" {
        id                = "arn:aws:elasticloadbalancing:us-east-1:371868434650:listener/app/todo20230422165407178000000004/074cc50941db12ee/d2a58629fce2835c"
        tags              = {}
        # (5 unchanged attributes hidden)

      ~ default_action {
          - target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:371868434650:targetgroup/todo20230422165404959600000002/6a490cc18b2df4a1" -> null
            # (2 unchanged attributes hidden)

          + forward {
              + stickiness {
                  + duration = 60
                  + enabled  = false
                }
              + target_group {
                  + arn    = "arn:aws:elasticloadbalancing:us-east-1:371868434650:targetgroup/todo20230422165404959600000002/6a490cc18b2df4a1"
                  + weight = 1
                }
            }
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Apply the run when ready.

```
> terraform apply
Running apply in Terraform Cloud. Output will stream here. Pressing Ctrl-C
will cancel the remote apply if it's still pending. If the apply started it
will stop streaming the logs, but will not stop the apply running remotely.

Preparing the remote apply...

To view this run in a browser, visit:
https://app.terraform.io/app/sudomateo/terraform-training-todo/runs/run-Q9ytg5Z31XJNHc9W

Waiting for the plan to start...
...
Do you want to perform these actions in workspace "terraform-training-todo"?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.todo.aws_lb_listener.lb: Modifying... [id=arn:aws:elasticloadbalancing:us-east-1:371868434650:listener/app/todo20230422165407178000000004/074cc50941db12ee/d2a58629fce2835c]
module.todo.aws_lb_listener.lb: Modifications complete after 0s [id=arn:aws:elasticloadbalancing:us-east-1:371868434650:listener/app/todo20230422165407178000000004/074cc50941db12ee/d2a58629fce2835c]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:
app_url = "http://todo20230422165407178000000004-1369944640.us-east-1.elb.amazonaws.com:8888"
```

## API-driven Runs

If you need even more flexibility in your workflow, Terraform Cloud/Enterprise
supports executing runs via the API.

Create a new Terraform Cloud/Enterprise workspace.

Create the necessary variables on your workspace.

Create an archive of the Terraform configuration that you want to run.

```
> tar -zcvf config.tar.gz main.tf .terraform.lock.hcl
main.tf
.terraform.lock.hcl
```

Retrieve the workspace ID for your workspace.

```
> curl \
  --header "Authorization: Bearer ${TOKEN}" \
  --header "Content-Type: application/vnd.api+json" \
    https://app.terraform.io/api/v2/organizations/sudomateo/workspaces/terraform-training-todo-api | jq '.data.id'
"ws-emy2arzyWsxnY2DB"
```

Create a `configuration-version.json` payload file.

```json
{
  "data": {
    "type": "configuration-versions",
    "attributes": {
      "auto-queue-runs": false
    }
  }
}
```

Create a configuration version for the workspace.

```
> curl \
  --header "Authorization: Bearer ${TOKEN}" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @configuration-version.json \
  https://app.terraform.io/api/v2/workspaces/ws-emy2arzyWsxnY2DB/configuration-versions | jq
{
  "data": {
    "id": "cv-gUeR6LtkKkmisTTf",
    "type": "configuration-versions",
    "attributes": {
      "auto-queue-runs": false,
      "error": null,
      "error-message": null,
      "source": "tfe-api",
      "speculative": false,
      "status": "pending",
      "status-timestamps": {},
      "changed-files": [],
      "upload-url": "https://archivist.terraform.io/v1/object/dmF1bHQ6djI6aUNNUG96cW5IbFQ3NjBQVjRnNlhCdGc0VmI5K3ozRjVrVnpLT3RGQm9BMUpVUUZmZTRsMWlza0pCamMyYzhxWnpIeXVneFBpQzVWZXJnZVd6NlNHZkNSWjVwMis5dHZaUGdLa2cweTFON3FQbFU3SDZpOGxuTkV6K0U1RUlTNFhrWlgwUWhqaWZPTGpPR1RCR3BoT3pYU1BJZ3FDc0lSS04yTnpyTGFCYlpxcTA2UEZEU0dSSmx3c0g0UTB1Q3NnZ3RkWUJVdVdmd0JkNm1GdUdpR21rMG9za1lFeWcyZ2lIbWVFK29IU1NuM3MrclZDNG9GdlJveUV6VFdhUGR2R3VUcFlvTVRUOWlycXNCMU4wMXE4dzlFeFlldE1hWEF2NUJsanF2eUZ1NUdmOWcxM01hY3lZVC91RDR4bFB3b2VlM0ZVWS96L2JpQjlQWUJD"
    },
    "relationships": {
      "ingress-attributes": {
        "data": null,
        "links": {
          "related": "/api/v2/configuration-versions/cv-gUeR6LtkKkmisTTf/ingress-attributes"
        }
      }
    },
    "links": {
      "self": "/api/v2/configuration-versions/cv-gUeR6LtkKkmisTTf"
    }
  }
}
```

Upload your Terraform configuration archive to the workspace.

```
> curl \
  --header "Content-Type: application/octet-stream" \
  --request PUT \
  --data-binary @config.tar.gz \
 https://archivist.terraform.io/v1/object/dmF1bHQ6djI6aUNNUG96cW5IbFQ3NjBQVjRnNlhCdGc0VmI5K3ozRjVrVnpLT3RGQm9BMUpVUUZmZTRsMWlza0pCamMyYzhxWnpIeXVneFBpQzVWZXJnZVd6NlNHZkNSWjVwMis5dHZaUGdLa2cweTFON3FQbFU3SDZpOGxuTkV6K0U1RUlTNFhrWlgwUWhqaWZPTGpPR1RCR3BoT3pYU1BJZ3FDc0lSS04yTnpyTGFCYlpxcTA2UEZEU0dSSmx3c0g0UTB1Q3NnZ3RkWUJVdVdmd0JkNm1GdUdpR21rMG9za1lFeWcyZ2lIbWVFK29IU1NuM3MrclZDNG9GdlJveUV6VFdhUGR2R3VUcFlvTVRUOWlycXNCMU4wMXE4dzlFeFlldE1hWEF2NUJsanF2eUZ1NUdmOWcxM01hY3lZVC91RDR4bFB3b2VlM0ZVWS96L2JpQjlQWUJD
```

Create a `run.json` payload file.

```json
{
  "data": {
    "attributes": {
      "message": "Triggered via API"
    },
    "type":"runs",
    "relationships": {
      "workspace": {
        "data": {
          "type": "workspaces",
          "id": "ws-emy2arzyWsxnY2DB"
        }
      },
      "configuration-version": {
        "data": {
          "type": "configuration-versions",
          "id": "cv-gUeR6LtkKkmisTTf"
        }
      }
    }
  }
}
```

Create a run on your workspace.

```
> curl \
  --header "Authorization: Bearer ${TOKEN}" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @run.json \
  https://app.terraform.io/api/v2/runs | jq '.data.id'
"run-jmczq7UkDshxHKT2"
```

Retrieve the run status.

```
> curl \
  --header "Authorization: Bearer ${TOKEN}" \
  https://app.terraform.io/api/v2/runs/run-jmczq7UkDshxHKT2 | jq '.data.attributes.status'
"planned"
```

Apply the run when ready.

```
> curl \
  --header "Authorization: Bearer ${TOKEN}" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{"comment":"Ship it!"}' \
  https://app.terraform.io/api/v2/runs/run-jmczq7UkDshxHKT2/actions/apply
```

## Private Module Registry

Terraform Cloud/Enterprise supports publishing modules to its Private Module
Registry. This allows you to share and version Terraform modules across your
Terraform Cloud/Enterprise organization.

This section will be demonstrated live during the course. The high level process
is as follows.

1. Push your module to a VCS repository.
1. Version that Terraform module with a VCS tag.
1. Configure VCS within Terraform Cloud/Enterprise.
1. Publish the module into your Private Module Registry.
1. Use that module in your workspace.

## Team, Governance, and Business Features

Terraform Cloud/Enterprise has different tiers that you can use depending on
your organization's needs. Each tier comes with different features. In this
section, we'll demo some of the most common features.

### Run Tasks

Run tasks allow Terraform Cloud/Enterprise to integrate with other services via
webhooks during different phases of the run.

This section will be demonstrated live during the course. The high level process
is as follows.

1. Create a run task where Terraform Cloud/Enterprise will send a webhook. Use
   https://webhook.site for free testing.
1. Configure your workspace to use the run task.
1. Start a new run and see the webhook hit https://webhook.site.
1. Respond to the webhook manually.

### Cost Estimation

Cost estimation allows Terraform Cloud/Enterprise to report estimated costs on
your workspace's infrastructure.

The estimate will show the total hourly and monthly costs for the managed
infrastructure as well as a delta for how a particular will affect those costs
if applied.

Not all resources are supported by cost estimation.

This section will be demonstrated live during the course. The high level process
is as follows.

1. Enable cost estimation for your organization.
1. Execute a run that manages supported resources.

### Policy Enforcement

Terraform Cloud/Enterprise supports writing Sentinel and Open Policy Agent
policies to enforce changes in your Terraform configuration, changes in cost
estimates, and even limit what time of day Terraform runs can occur.

#### Sentinel

Let's add a Sentinel policy set to our VCS repository that we can use in our
Terraform runs.

The directory structure we'll create is:

```
.
└── sentinel
    └── aws
        ├── database-engine.sentinel
        └── sentinel.hcl
```

The `sentinel/aws/database-engine.sentinel` file:

```
import "tfplan/v2" as tfplan

param allowed_db_instance_engines default [ "postgres" ]

# Get all `aws_db_instance` resources from all modules.
db_instances = filter tfplan.resource_changes as _, rc {
    rc.type is "aws_db_instance"
}

# Check if each `aws_db_instance` resource is using an allowed database engine.
db_instance_engine_allowed = rule {
    all db_instances as _, db_instance {
        db_instance.change.after.engine in allowed_db_instance_engines
    }
}

main = rule {
    db_instance_engine_allowed
}
```

The `sentinel/aws/sentinel.hcl` file:

```hcl
policy "database-engine" {
  source            = "./database-engine.sentinel"
  enforcement_level = "hard-mandatory"
}
```

With these changes pushed to our repository, we can now use this policy set in
our Terraform runs.

This section will be demonstrated live during the course. The high level process
is as follows.

1. Create a Sentinel policy set using a VCS respository.
1. Attach our workspace to the Sentinel policy set.
1. Execute a run on the attached workspace.

We can test Sentinel policies locally using Terraform mock data.

The directory structure of our VCS repository for Sentinel will change to:

```
.
└── sentinel
    └── aws
        ├── database-engine.sentinel
        ├── sentinel.hcl
        ├── test
        │   └── database-engine
        │       ├── fail.hcl
        │       └── pass.hcl
        └── testdata
            ├── mock-tfconfig.sentinel
            ├── mock-tfconfig-v2.sentinel
            ├── mock-tfplan.sentinel
            ├── mock-tfplan-v2.sentinel
            ├── mock-tfrun.sentinel
            ├── mock-tfstate.sentinel
            └── mock-tfstate-v2.sentinel
```

This section will be demonstrated live during the course. The high level process
is as follows.

1. Install HashiCorp Sentinel CLI.
1. Download Terraform mock data and extract it to `testdata`.
1. Write tests in `test`.
1. Use `sentinel test` to test the Sentinel policies.

#### Open Policy Agent


Let's add an Open Policy Agent policy set to our VCS repository that we can use
in our Terraform runs.

The directory structure we'll create is:

```
.
└── opa
    └── aws
        ├── database_engine.rego
        └── policies.hcl
```

The `opa/aws/database_engine.rego` file:

```rego
package terraform.policies.aws.database_engine

import future.keywords.in
import input.plan as tfplan

engines := [
    ["postgres"],
]

resources := [resource_changes |
    resource_changes := tfplan.resource_changes[_]
    resource_changes.type == "aws_db_instance"
]

violations := [resource |
    resource := resources[_]
    not resource.change.after.engine in engines
]

violators[address] {
    address := violations[_].address
}

rule[msg] {
    count(violations) != 0
  msg := sprintf(
    "%d %q severity resource violation(s) have been detected.",
        [count(violations), rego.metadata.rule().custom.severity]
    )
}
```

The `opa/aws/policies.hcl` file:

```hcl
policy "database_engine" {
  query = "data.terraform.policies.aws.database_engine.rule"
  enforcement_level = "mandatory"
}
```

With these changes pushed to our repository, we can now use this policy set in
our Terraform runs.

This section will be demonstrated live during the course. The high level process
is as follows.

1. Create an Open Policy Agent policy set using a VCS respository.
1. Attach our workspace to the Sentinel policy set.
1. Execute a run on the attached workspace.
