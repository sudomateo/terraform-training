# The resource type is `null_resource`.
# The resource name is `example_app`.
# The resource has an attribute named `triggers`.
resource "null_resource" "example_app" {
  triggers = {
    some_key = "some_value"
  }
}

# The resource type is `local_file`.
# The resource name is `example_file`.
# The resource has an attribute named `content`.
# The resource has an attribute named `filename`.
resource "local_file" "example_file" {
  content  = "Hello, world!"
  filename = "example.txt"
}
