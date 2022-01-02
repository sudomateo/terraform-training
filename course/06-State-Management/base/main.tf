output "image_foo" {
  value = "ghcr.io/sudomateo/todo:foo"
}

output "image_bar" {
  value = "ghcr.io/sudomateo/todo:bar"
}

output "password" {
  value     = "ifitsfreeitsterraforme"
  sensitive = true
}
