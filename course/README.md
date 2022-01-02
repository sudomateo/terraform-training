# Course Curriculum

## 01 Getting Started

Install Terraform and familiarize yourself with your cloud provider.

- What is Terraform?
- How does Terraform work?
- Why use Terraform?
- Terraform Installation
- Editor Configuration
- Cloud Provider Configuration

## 02 Terraform Basics

Learn the Terraform configuration syntax and use Terraform to provision infrastructure. 

- Configuration Syntax
- The Core Workflow
- Modifying Infrastructure
- Terraform State
- Destroying Infrastructure

## 03 Terraform Language

Use all of the top-level configuration keywords in Terraform.

- Providers
- Resources
- Data Sources
- Variables
- Outputs
- Locals

## 04 Provisioners

Use Provisioners to extend Terraform with imperative workflows.

- What are Provisioners?
- Declaring Provisioners
- The `local-exec` Provisioner
- The `remote-exec` Provisioner
- The `file` Provisioner
- Provisioners Without a Resource
- Alternatives to Provisioners

## 05 Modules

Create reusable abstractions of Terraform configuration using Modules.

- What are Modules?
- Using Modules
- Developing Modules
- Providers in Modules
- Module Sources
- Publishing Modules to the Terraform Registry

## 06 State Management

Understand and interact with Terraform state.

- Inspecting Infrastructure
- Importing Infrastructure
- Manipulating State
- Refreshing State
- The `terraform_remote_state` Data Source
- Understanding Secrets in State

## 07 State Backends

Store Terraform state securely and prevent state corruption with state locking.

- The Local Backend
- Remote Backends
- Configuring Remote State Storage
- State Locking
- Configuring Remote State Locking
- Migrating State Between Backends

## 08 Workspaces

Deploy a clone of your infrastructure using Workspaces.

- What are Workspaces?
- Avoiding Infrastructure Collisions
- Using Workspaces
- Alternatives to Workspaces

## 09 Advanced Terraform Configuration

Use advanced Terraform features to DRY up your configuration and scale deployments.

- Functions
- Expressions
- Scaling with `count`
- Scaling with `for_each`
- Dynamic Blocks
- Custom Conditions
- Terraform Console
- Override Files

## 10 Terraform in Automation

Integrate Terraform with your CI/CD workflows.

- Verifying Terraform Configuration
- Running Terraform in CI/CD
- Terraform CLI Configuration
- Using Custom Providers
- Debugging Terraform
- Tuning Terraform

## 11 Terraform Cloud & Terraform Enterprise

Extend Terraform with features from Terraform Cloud and Terraform Enterprise.

- What is Terraform Cloud and Terraform Enterprise?
- VCS-driven Runs
- CLI-driven Runs
- API-driven Runs
- Private Module Registry
- Team, Governance, and Business Features

## 12 Developing a Terraform Provider

Integrate Terraform with an API by developing a custom Terraform provider.

- Making CRUD Requests to an API
- Terraform Plugin Framework
- Building a Go SDK for the API
- Implement a Data Source
- Implement Create and Read
- Implement Update
- Implement Delete
- Implement Import
