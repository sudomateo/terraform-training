resource "null_resource" "example_app" {
  triggers = {
    some_key = "some_value"
  }
}

# This resource is accessing the value of the `triggers` attribute from the
# `null_resource.example_app` resource above.
#
# Since this resource is accessing another resource's attribute, there is an
# implicit dependency between this `null_resource.example_db` resource and the
# `null_resource.example_app` resource above.
resource "null_resource" "example_db" {
  triggers = null_resource.example_app.triggers
}
