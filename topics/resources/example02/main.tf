resource "null_resource" "example_app" {
  triggers = {
    some_key = "some_value"
  }
}

resource "null_resource" "example_db" {
  triggers = null_resource.example_app.triggers
}
