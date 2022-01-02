# Required variables.
variable "user_data" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

# Optional variables.
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
