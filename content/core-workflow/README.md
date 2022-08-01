# The Core Terraform Workflow

The core Terraform workflow has three steps:

1. Write - Create Terraform configuration.
1. Plan - Preview changes before applying.
1. Apply - Provision infrastructure.

```mermaid
flowchart LR
	write[Write]
	plan[Plan]
	apply[Apply]

	write --> plan --> apply
	plan -.-> write
	apply -.-> plan & write
```

## Outline

- [Configuration Syntax](configuration-syntax)
- [Provisioning Infrastructure](provisioning-infrastructure)
- [Providers and Resources](providers-and-resources)
- [Destroying Infrastructure](destroying-infrastructure)
