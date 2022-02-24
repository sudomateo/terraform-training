resource "null_resource" "example" {
  triggers = {
    Hello = "World",
  }
}
