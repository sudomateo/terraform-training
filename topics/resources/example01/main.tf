resource "null_resource" "example_app" {
  triggers = {
    some_key = "some_value"
  }
}
