output "ssh_info" {
  value = "ssh -l ubuntu ${aws_instance.app.public_ip}"
}

output "app_url" {
  value = "http://${aws_instance.app.public_ip}:${var.app_port}"
}
