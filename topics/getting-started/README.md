# Getting Started

## What is Terraform?

Terraform is a tool that allows you to declaratively define resources as code and perform create, read, update, or delete (CRUD) operations against those resources. Put another way, Terraform is a stateful, declarative wrapper around CRUD APIs.

Often, you might hear people refer to Terraform as an "infrastructure as code" tool. While that is true, Terraform is not limited to managing just infrastructure. It can manage any resource that is fronted by a CRUD API, including:

- AWS, Azure, and GCP virtual machines.
- Kubernetes deployments.
- GitHub repositories.
- PagerDuty schedules.

## Why use Terraform?

If you ever had to manually create resources by clicking around in a user interface, you'll know that the process is time consuming, error prone, and just plain boring. Terraform addresses those issues by:

- Being declarative. You define the end state of resources and Terraform works to make that a reality.
- Being idempotent. Terraform only updates resources when they need updating.
- Being programmatic. Want 1 resource? 100? That's a one line change in the code instead of manually clicking around again and again.
- Being reusable. Want to share configuration with your team? Store that configuration in source control and share it around!

## Installing Terraform

Download and install Terraform from https://www.terraform.io/downloads.

Ensure the `terraform` (macOS and Linux) or `terraform.exe` (Windows) binary is on your `PATH`.

### Graphviz

Terraform can generate a graph of its resources. To visualize this graph, install [Graphviz](https://graphviz.org/). While not a requirement to use Terraform, it helps make use of features provided by `terraform graph`.

## Executing Terraform

At a high level, there are three steps to executing Terraform:

- Initializing the configuration using `terraform init`.
- Executing a plan using `terraform plan`.
- Executing an apply using `terraform apply`.
