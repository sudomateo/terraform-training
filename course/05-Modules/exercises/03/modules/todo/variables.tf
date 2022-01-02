# Required variables.
variable "ssh_public_key" {
  type = string
}

# Optional variables.
variable "app_port" {
  type    = number
  default = 8080
}

variable "app_version" {
  type    = string
  default = "dev"
}

variable "db_name" {
  type    = string
  default = "todo"
}

variable "db_user" {
  type    = string
  default = "todo"
}

variable "db_password" {
  type    = string
  default = "todopassword"
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
