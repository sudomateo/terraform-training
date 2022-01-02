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

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
