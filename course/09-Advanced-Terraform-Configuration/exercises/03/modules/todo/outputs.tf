output "app_url" {
  value = "http://${aws_lb.lb.dns_name}:${var.ingress_port}"
}
