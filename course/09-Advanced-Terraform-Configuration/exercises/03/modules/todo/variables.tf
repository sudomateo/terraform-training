# Required variables.
variable "ssh_public_key" {
  description = "SSH public key to attach to the instances. Set to `null` to have an SSH key generated for you."
  type        = string

  validation {
    condition     = var.ssh_public_key != null && var.ssh_public_key != ""
    error_message = "SSH key cannot be `null` or empty."
  }
}

# Optional variables.
variable "app" {
  description = <<-EOF
  Application settings. All fields are optional.
  EOF

  type = object({
    image         = optional(string, "ghcr.io/sudomateo/todo:latest")
    version       = optional(string, "dev")
    port          = optional(number, 8080)
    instance_type = optional(string, "t3.micro")
  })

  default = {
    image         = "ghcr.io/sudomateo/todo:latest"
    version       = "dev"
    port          = 8080
    instance_type = "t3.micro"
  }

  validation {
    condition = (
      var.app.image != null && var.app.image != "" &&
      var.app.version != null && var.app.version != "" &&
      var.app.port != null &&
      var.app.instance_type != null && var.app.instance_type != ""
    )
    error_message = "Database settings cannot be null."
  }
}

variable "db" {
  description = <<-EOF
  Database settings. All fields are optional. When the password is left blank
  one will be generated for you.
  EOF
  type = object({
    name           = optional(string, "todo")
    user           = optional(string, "todo")
    password       = optional(string, "")
    port           = optional(number, 5432)
    instance_class = optional(string, "db.t3.micro")
  })

  default = {
    name           = "todo"
    user           = "todo"
    password       = ""
    port           = 5432
    instance_class = "db.t3.micro"
  }

  validation {
    condition = (
      var.db.name != null && var.db.name != "" &&
      var.db.user != null && var.db.user != "" &&
      var.db.password != null &&
      var.db.port != null &&
      var.db.instance_class != null && var.db.instance_class != ""
    )
    error_message = "Database settings cannot be null."
  }
}

variable "ingress_port" {
  description = "Port for the application ingress."
  type        = number
  default     = 80
}
