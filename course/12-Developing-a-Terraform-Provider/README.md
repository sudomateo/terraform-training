# Developing a Terraform Provider

In this section, you will learn how to do the following:

- Interact with an existing CRUD API using `curl`.
- Describe what the Terraform plugin framework is.
- Build a Go SDK to interfact with an existing CRUD API.
- Create a Terraform provider to interact with an existing CRUD API.

## Making CRUD Requests to an API

In order to develop a Terraform provider we'll need access to a CRUD API.
Luckily for us, the todo application has a CRUD API we can use.

Deploy the todo application if you haven't done so already. Once it's up, create
a todo using the web interface.

The todo application has a CRUD API at `/api`. Let's take a look at it.

We can list all todos using `GET /todo`.

```
> curl http://todo20230422165407178000000004-1369944640.us-east-1.elb.amazonaws.com:8888/api/todo | jq
[
  {
    "id": "b9d31d81-0489-4d1f-a4f1-0b32365f3e1e",
    "text": "Complete the Terraform training material.",
    "priority": "medium",
    "completed": false,
    "time_created": "2023-04-23T04:35:03.045616Z",
    "time_updated": "2023-04-23T04:35:03.045616Z"
  }
]
```

We can retrieve details about a single todo using `GET /todo/:id`.

```
> curl http://todo20230422165407178000000004-1369944640.us-east-1.elb.amazonaws.com:8888/api/todo/b9d31d81-0489-4d1f-a4f1-0b32365f3e1e | jq
{
  "id": "b9d31d81-0489-4d1f-a4f1-0b32365f3e1e",
  "text": "Complete the Terraform training material.",
  "priority": "medium",
  "completed": false,
  "time_created": "2023-04-23T04:35:03.045616Z",
  "time_updated": "2023-04-23T04:35:03.045616Z"
}
```

We can create a new todo using `POST /todo`.

```
> curl --request POST --data '{"text": "Use the todo API", "priority": "medium"}' http://todo20230422165407178000000004-1369944640.us-east-1.elb.amazonaws.com:8888/api/todo | jq
{
  "id": "c7977a88-42ca-4fa5-835f-b34745316b7b",
  "text": "Use the todo API",
  "priority": "medium",
  "completed": false,
  "time_created": "2023-04-23T04:41:00.654931478Z",
  "time_updated": "2023-04-23T04:41:00.654931478Z"
}
```

We can update an existing todo using `PATCH /todo/:id`.

```
> curl --request PATCH --data '{"completed": true}' http://todo20230422165407178000000004-1369944640.us-east-1.elb.amazonaws.com:8888/api/todo/c7977a88-42ca-4fa5-835f-b34745316b7b | jq
{
  "id": "c7977a88-42ca-4fa5-835f-b34745316b7b",
  "text": "Use the todo API",
  "priority": "medium",
  "completed": true,
  "time_created": "2023-04-23T04:41:00.654931Z",
  "time_updated": "2023-04-23T04:42:10.209745125Z"
}
```

We can delete an existing tod using `DELETE /todo/:id`.

```
> curl --request DELETE http://todo20230422165407178000000004-1369944640.us-east-1.elb.amazonaws.com:8888/api/todo/c7977a88-42ca-4fa5-835f-b34745316b7b
```

Our Terraform provider will interact with this CRUD API.

## Terraform Plugin Framework

The [Terraform plugin
framework](https://developer.hashicorp.com/terraform/plugin/framework) is the
recommended way to develop a provider for Terraform.

The plugin framework provides us with the following concepts to develop a
Terraform provider.

- [Provider Servers](https://developer.hashicorp.com/terraform/plugin/framework/provider-servers)
- [Providers](https://developer.hashicorp.com/terraform/plugin/framework/providers)
- [Schemas](https://developer.hashicorp.com/terraform/plugin/framework/handling-data/schemas)
- [Resources](https://developer.hashicorp.com/terraform/plugin/framework/resources)
- [Data Sources](https://developer.hashicorp.com/terraform/plugin/framework/data-sources)

Let's take a closer look at some of interfaces provided by this framework.

The `Provider` inteface.

```go
type Provider interface {
	// Metadata should return the metadata for the provider, such as
	// a type name and version data.
	//
	// Implementing the MetadataResponse.TypeName will populate the
	// datasource.MetadataRequest.ProviderTypeName and
	// resource.MetadataRequest.ProviderTypeName fields automatically.
	Metadata(context.Context, MetadataRequest, *MetadataResponse)

	// Schema should return the schema for this provider.
	Schema(context.Context, SchemaRequest, *SchemaResponse)

	// Configure is called at the beginning of the provider lifecycle, when
	// Terraform sends to the provider the values the user specified in the
	// provider configuration block. These are supplied in the
	// ConfigureProviderRequest argument.
	// Values from provider configuration are often used to initialise an
	// API client, which should be stored on the struct implementing the
	// Provider interface.
	Configure(context.Context, ConfigureRequest, *ConfigureResponse)

	// DataSources returns a slice of functions to instantiate each DataSource
	// implementation.
	//
	// The data source type name is determined by the DataSource implementing
	// the Metadata method. All data sources must have unique names.
	DataSources(context.Context) []func() datasource.DataSource

	// Resources returns a slice of functions to instantiate each Resource
	// implementation.
	//
	// The resource type name is determined by the Resource implementing
	// the Metadata method. All resources must have unique names.
	Resources(context.Context) []func() resource.Resource
}
```

The `Resource` interface.

```go
type Resource interface {
	// Metadata should return the full name of the resource, such as
	// examplecloud_thing.
	Metadata(context.Context, MetadataRequest, *MetadataResponse)

	// Schema should return the schema for this resource.
	Schema(context.Context, SchemaRequest, *SchemaResponse)

	// Create is called when the provider must create a new resource. Config
	// and planned state values should be read from the
	// CreateRequest and new state values set on the CreateResponse.
	Create(context.Context, CreateRequest, *CreateResponse)

	// Read is called when the provider must read resource values in order
	// to update state. Planned state values should be read from the
	// ReadRequest and new state values set on the ReadResponse.
	Read(context.Context, ReadRequest, *ReadResponse)

	// Update is called to update the state of the resource. Config, planned
	// state, and prior state values should be read from the
	// UpdateRequest and new state values set on the UpdateResponse.
	Update(context.Context, UpdateRequest, *UpdateResponse)

	// Delete is called when the provider must delete the resource. Config
	// values may be read from the DeleteRequest.
	//
	// If execution completes without error, the framework will automatically
	// call DeleteResponse.State.RemoveResource(), so it can be omitted
	// from provider logic.
	Delete(context.Context, DeleteRequest, *DeleteResponse)
}
```

The `DataSource` interface.

```go
type DataSource interface {
	// Metadata should return the full name of the data source, such as
	// examplecloud_thing.
	Metadata(context.Context, MetadataRequest, *MetadataResponse)

	// Schema should return the schema for this data source.
	Schema(context.Context, SchemaRequest, *SchemaResponse)

	// Read is called when the provider must read data source values in
	// order to update state. Config values should be read from the
	// ReadRequest and new state values set on the ReadResponse.
	Read(context.Context, ReadRequest, *ReadResponse)
}
```

## Building a Go SDK for the API

It is considered good practice for Terraform providers to use a Go SDK to
interact with a CRUD API instead of making HTTP requests directly.

Let's build a Go SDK for our todo application so that we can leverage it in our
Terraform provider.

The SDK will use the following types.

```go
// Todo represents a todo item.
type Todo struct {
	ID          uuid.UUID `json:"id"`
	Text        string    `json:"text"`
	Priority    Priority  `json:"priority"`
	Completed   bool      `json:"completed"`
	TimeCreated time.Time `json:"time_created"`
	TimeUpdated time.Time `json:"time_updated"`
}

// Priority is an enum that represents the different priorities a todo item can
// have.
type Priority string

const (
	PriorityLow    Priority = "low"
	PriorityMedium Priority = "medium"
	PriorityHigh   Priority = "high"
)

// TodoCreateParams are what we require from clients to create a todo item.
type TodoCreateParams struct {
	Text     string   `json:"text"`
	Priority Priority `json:"priority"`
}

// TodoUpdateParams represents the information that clients can modify for a
// todo item. Pointers are used to determine whether or not a field was
// provided by the client.
type TodoUpdateParams struct {
	Text      *string   `json:"text"`
	Priority  *Priority `json:"priority"`
	Completed *bool     `json:"completed"`
}
```

The Go client will use the following type and constructor function as a base.

```go
// Client is a Go HTTP client to interact with the Todo API.
type Client struct {
	baseURL *url.URL
	http    *http.Client
}

// NewClient creates a new Client using rawURL as the base URL for the Todo
// API.
func NewClient(rawURL string) (*Client, error) {
	baseURL, err := url.Parse(rawURL)
	if err != nil {
		return nil, err
	}

	c := Client{
		baseURL: baseURL,
		http:    &http.Client{Timeout: 10 * time.Second},
	}

	return &c, nil
}
```

The client will have the following methods to specify the behavior that we want.

```go
// ListTodos retrieves a list of all todos from the API.
func (c *Client) ListTodos() ([]Todo, error) {}

// GetTodo retrieves a single todo by its id from the API.
func (c *Client) GetTodo(id string) (Todo, error) {}

// CreateTodo creates a todo.
func (c *Client) CreateTodo(params TodoCreateParams) (Todo, error) {}

// UpdateTodo updates an existing todo given by id.
func (c *Client) UpdateTodo(id string, params TodoUpdateParams) (Todo, error) {}

// DeleteTodo deletes a todo by its id.
func (c *Client) DeleteTodo(id string) error {}
```

Filling out these methods will be demonstrated live during the course.

## Implement a Data Source

This section will be demonstrated live during the course.

## Implement Create and Read

This section will be demonstrated live during the course.

## Implement Update

This section will be demonstrated live during the course.

## Implement Delete

This section will be demonstrated live during the course.

## Implement Import

This section will be demonstrated live during the course.
