# Provisioners

In this section, you will learn how to do the following:

- Describe what provisioners are and when to use them.
- Use the `local-exec`, `remote-exec`, and `file` provisioners.
- Use the `null_resource` resource to execute provisioners without a resource.
- Describe alternatives to provisioners.

## What Are Provisioners?

Provisioners are used to extend Terraform by executing processes on the local
machine running Terraform or on remote hosts provisioned by Terraform.

### Provisioners Are a Last Resort

Terraform's declarative model works well with managing immutable
infrastructure. However, some infrastructure requires a more imperative
approach to management and configuration. Provisioners are meant to bridge this
gap by providing a way for Terraform to execute an imperative process within
its declarative model.

Provisioners are a last resort. They should be used sparingly and only when
absolutely necessary.

## Declaring Provisioners

Provisioners are declared using `provisioner` blocks within a resource.

```hcl
resource "aws_instance" "app" {
  # ...

  provisioner "local-exec" {
    command = "echo Instance ID: ${self.id}"
  }
}
```

You can declare multiple `provisioner` blocks within a resource. They will be
executed in the order declared.

```hcl
resource "aws_instance" "app" {
  # ...

  provisioner "local-exec" {
    command = "echo first"
  }

  provisioner "local-exec" {
    command = "echo second"
  }
}
```

### Creation-Time Provisioners

By default, provisioners execute after a resource is created and do not execute
when a resource is destroyed. These are called creation-time provisioners.

### Destroy-Time Provisioners

To change the default behavior and execute a provisioner when a resource is
destroyed and not when it is created, use the `when` attribute. These are
called destroy-time provisioners.

```hcl
resource "aws_instance" "app" {
  # ...

  provisioner "local-exec" {
    when    = destroy
    command = "echo Instance ID: ${self.id}"
  }
}
```

Destroy-time provisioners can only execute when the resource containing the
provisioner remains in the configuration at the time of destruction.

### Failure Behavior

By default, provisioners that fail cause the Terraform apply to fail. To change
this behavior, use the `on_failure` attribute.

```hcl
resource "aws_instance" "app" {
  # ...

  provisioner "local-exec" {
    on_failure = continue
    command    = "echo Instance ID: ${self.id}"
  }
}
```

## The `local-exec` Provisioner

The `local-exec` provisioner executes a process after a resource is
provisioned. The process is executed on the machine running Terraform.

A common use case for the `local-exec` provisioner is to do something with the
newly created resource that may not be possible to do in Terraform.

```hcl
resource "aws_instance" "app" {
  # ...

  provisioner "local-exec" {
    command = "aws ec2 describe-instances --instance-ids ${self.id}"
  }
}
```

The `local-exec` provisioner is also a good tool for troubleshooting Terraform.

```hcl
resource "aws_instance" "app" {
  # ...

  provisioner "local-exec" {
    command = "ls -la"
  }
}
```

## The `remote-exec` Provisioner

The `remote-exec` provisioner executes a process after a resource is
created. The process is executed on a remote machine.

A common use case for the `remote-exec` provisioner is to run configuration
management tools or install packages on the created resource.

```hcl
resource "aws_instance" "app" {
  # ...

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file("~/.ssh/id_ed25519")
    }

    inline = [
      "sudo apt update",
      "sudo apt install -y nginx",
      "sudo systemctl enable --now nginx",
    ]
  }
}
```

## The `file` Provisioner

The `file` provisioner copies files or directories from the machine running
Terraform to the created resource.

A common use case for the `file` provisioner is to copy configuration files to
the resource.

```hcl
resource "aws_instance" "app" {
  # ...

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file("~/.ssh/id_ed25519")
    }

    content     = "log_level = info"
    destination = "/etc/app.conf"
  }
}
```

## Provisioners Without a Resource

If you need to execute provisioners but don't have a resource to associate the
provisioner with, you can associate the resource with a `null_resource`.

All `null_resource` resources are treated like normal resources but they don't
actually provision any real infrastructure.

```hcl
terraform {
  required_providers {
    # ...
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "null_resource" "null" {
  provisioner "local-exec" {
    command = "script.sh"
  }
}
```

The `null_resource` resource supports a `triggers` attribute that can be used
to recreate the `null_resource` and re-run its provisioners.

```hcl
resource "aws_instance" "app" {
  # ... 
}

resource "null_resource" "null" {
  # Changes to the instance's public IP will trigger this `null_resource` to be
  # recreated and re-run the provisioners.
  triggers = {
    instance_id = aws_instance.app.public_ip
  }

  provisioner "local-exec" {
    command = "script.sh"
  }
}
```

## Alternatives to Provisioners

Provisioners are a last resort. There are better alternatives for most use
cases.

### Immutable Infrastructure

Terraform's declarative model works well with managing immutable
infrastructure.

Traditionally, infrastructure was deployed once from a base image and then
continuously configured using configuration management software. When it was
time to deploy a new version of a service, the configuration management
software would stop the service, install the new version of the service, and
start the service again. This long-living instance is known as mutable
infrastructure, or pets.

Today, we build images containing a specific version of a service. When it is
time to deploy a new version of a service, we destroy the instance running the
old service and spin up a new instance running the new service. The images for
these instances are immutable in that we no longer mutate the content inside
when upgrading services, we just deploy an entirely new instance using a newer
image. This type of instance is known as immutable infrastructure, or cattle.

Containers are a prime example of immutable infrastructure. However, you may
not always have a container to deploy. In those cases, you'll have to create an
image using something like
[HashiCorp Packer](https://developer.hashicorp.com/packer). The process to
create and use an immutable image might look something like this:

- Spin up an instance using a generic base image.
- Install a specific version of your service.
- Create an immutable image from this instance.
- Use Terraform to deploy this immutable image.
- Repeat for the new version of your service.

If possible, using immutable infrastructure with Terraform is the recommended
approach for a production deployment.

### Instance User Data

If you can't use immutable infrastructure, then another good alternative to
provisioners is to use instance user data to configure the instance.

User data allows your instance to execute arbitrary scripts and configure
itself when it starts up. Under the hood, the instance uses
[cloud-init](https://cloudinit.readthedocs.io/en/latest/) to process this user
data and perform the necessary configuration.

```hcl
resource "aws_instance" "app" {
  name                   = "app"
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.app.key_name
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = <<EOF
#!/bin/bash

sudo apt update

sudo apt install -y nginx

sudo systemctl enable --now nginx
EOF
}
```
