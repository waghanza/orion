<p align="center"><img src="https://raw.githubusercontent.com/obsidian/orion/v3.0.0-dev/orion-banner.svg" width="300"></p>

<p align="center">
  <img src="https://travis-ci.org/obsidian/orion.svg?branch=master" />
  <img src="https://img.shields.io/github/tag/obsidian/orion.svg?v=1" />
</p>

<hr />

## The 3 Flavors of Orion

| Simple | Complex | As a Framework |
| --- | --- | --- |
| Single File Application | Routes, Controllers in Other Files | Fully Functional View/Controller Framework



### Simple

```crystal
require "orion"
include Orion::DSL

get "/" do
  "Hello World"
end
```

Orion allows you to easily add routes, groups, and middleware in order to
construct your application’s routing layer.

## Purpose

The purpose of the Orion router is to connect URLs to code. It provides a flexible
and comprehensive DSL that will allow you to cover a variety of use cases. In addition,
Orion will also generate a series of helpers to easily reference the defined paths
within your application.

## Installation

Add this to your application’s `shard.yml`:

``` yaml
dependencies:
  orion:
    github: obsidian/orion
```

1.  and require Orion in your project.

<!-- -->

```crystal
require "orion"
```

## Usage

### Defining a router

You can define a router by using the `router` macro with a constant name.

```crystal
router MyApplicationRouter do
  # ...
end
```

### Generic route arguments

There are a variety of ways that you can interact with basic routes. Below are
some examples and guidelines on the different ways you can interact with the router.

#### Using `to: String` to target a controller and action

One of the most common ways we will be creating routes in this guide is to use
the `to` argument supplied with a controller and action in the form of a string.
In the example below `Users#create` will map to `UsersController.new(cxt : HTTP::Server::Context).create`.

```crystal
router MyApplicationRouter do
  post "users", to: "Users#create"
end
```

##### Non-constant

When passing a lowercased string, it still camelcase the string and add Controller.
In the example below `users#create` will map to `UsersController.new(cxt : HTTP::Server::Context).create`.

```crystal
router MyApplicationRouter do
  post "users", to: "users#create"
end
```

#### Using `controller: Type` and `action: Method`

A longer form of the `to` argument strategy above allows us to pass the controller and action
independently.

```crystal
router MyApplicationRouter do
  post "users", controller: UsersController, action: create
end
```

#### Using block syntax

Sometimes, we may want a more [kemal](https://github.com/kemalcr/kemal) or
[sinatra](http://sinatrarb.com/) like approach. To accomplish this, we can
simply pass a block that yields `HTTP::Server::Context`.

```crystal
router MyApplicationRouter do
  post "users" do |context|
    context.response.puts "foo"
  end
end
```

#### Using a `call` able object

Lastly a second argument can be any
object that responds to `#call(cxt : HTTP::Server::Context)`.

```crystal
router MyApplicationRouter do
  post "users", ->(context : HTTP::Server::Context) {
    context.response.puts "foo"
  }
end
```

### Basic Routing

#### Base route using `root`

Let’s define the routers’ `root` route. `root` is simply an alias for `get '/', action`.
All routes can either be a `String` pointing to a Controller action or a `Proc`
accepting `HTTP::Server::Context` as a single argument. If a `String` is used like `controller#action`, it will expand into `Controller.new(context : HTTP::Server::Context).action`, therefor A controller must
have an initializer that takes `HTTP::Server::Context` as an argument, and the
specified action must not contain arguments.

```crystal
  router MyApplicationRouter do
    root to: "home#index"
  end
```

#### HTTP verb based routes

A common way to interact with the router is to use standard HTTP verbs. Orion
supports all the standard HTTP verbs:

`get`, `head`, `post`, `put`, `delete`, `connect`, `options`, `trace`, and `patch`

You can use one of the methods within the router and pass it’s route and
any variation of the [Generic Route Arguments](#generic-route-arguments).

```crystal
router MyApplicationRouter do
  post "users", to: "users#create"
end
```

#### Catch-all routes using `match`

In some instances, you may just want to redirect all verbs to a particular
controller and action.

You can use the `match` method within the router and pass it’s route and
any variation of the [Generic Route Arguments](#generic-route-arguments).

```crystal
router MyApplicationRouter do
  match "404", controller: ErrorsController, action: error_404
end
```

#### Websocket routes

Orion has WebSocket support.

You can use the `ws` method within the router and pass it’s route and
any variation of the [Generic Route Arguments](#generic-route-arguments).

```crystal
router MyApplicationRouter do
  ws "/socket", controller: WebSocketController, action: main
end
```

### Resource-Based Routing

A common way in Orion to route is to do so against a known resource. This method
will create a series of routes targeted at a specific controller.

*The following is an example controller definition and the matching
resources definition.*

```crystal
class PostsController < MyRouter::BaseController
  def index
    @posts = Post.all
    render :index
  end

  def new
    @post = Post.new
    render :new
  end

  def create
    post = Post.create(request)
    redirect to: post_path post_id: post.id
  end

  def show
    @post = Post.find(request.path_params["post_id"])
  end

  def edit
    @post = Post.find(request.path_params["post_id"])
    render :edit
  end

  def update
    post = Post.find(request.path_params["post_id"])
    HTTP::FormData.parse(request) do |part|
      post.attributes[part.name] = part.body.gets_to_end
    end
    redirect to: post_path post_id: post.id
  end

  def delete
    post = Post.find(request.path_params["post_id"])
    post.delete
    redirect to: posts_path
  end

end

router MyApplication do
  resources :posts
end
```

#### Including/Excluding Actions

By default, the actions `index`, `new`, `create`, `show`, `edit`, `update`, `delete`
are included. You may include or exclude explicitly by using the `only` and `except` params.

> NOTE: The index action is not added for [singular resources](#singular-resources).

```crystal
router MyApplication do
  resources :posts, except: [:edit, :update]
  resources :users, only: [:new, :create, :show]
end
```

#### Nested Resources and Routes

You can add nested resources and member routes by providing a block to the
`resources` definition.

```crystal
router MyApplication do
  resources :posts do
    post "feature", action: feature
    resources :likes
    resources :comments
  end
end
```

#### Singular Resources

In addition to using the collection of `resources` method, You can also add
singular resources which do not provide a `id_param` or `index` action.

```crystal
router MyApplication do
  resource :profile
end
```

#### Customizing ID

You can customize the ID path parameter by passing the `id_param` parameter.

```crystal
router MyApplication do
  resources :posts, id_param: :article_id
end
```

#### Constraining the ID

You can set constraints on the ID parameter by passing the `id_constraint` parameter.

*see [param constraints](#param-constraints) for more details*

```crystal
router MyApplication do
  resources :posts, id_constraint: /^\d{4}$/
end
```

#### Constraints

Similar to basic routes, `resource` and `resources` support the
[`format`](#format-constraints), [`accept`](#accept-type-constraints),
[`content_type`](#content-type-constraints), and [`type`](#type-constraints)
constraints.

### Defining Controllers

There are a few ways to define controllers within your application. Controllers
are a useful way to separate concerns from your application.

You may inherit or extend from the routers `BaseController` or `WebSocketBaseController`, this will expose the helper methods from the router to all inherited controllers from the base. Caveat: Ensure that controllers are required
after your router is defined.

```crystal
class ApplicationController < MyApp::ControllerBase
  def home
    response.puts "you are home"
  end
end
```

### Instrumenting handlers *(a.k.a. middleware)*

Instances or Classes implementing
[`HTTP::Handler`](https://crystal-lang.org/api/HTTP/Handler.html) *(a.k.a. middleware)*
can be inserted directly in your routes by using the `use` method.

> Handlers will only apply to the routes specified below them, so be sure to place
> your handlers near the top of your route.

```crystal
router MyApplicationRouter do
  use HTTP::ErrorHandler
  use HTTP::LogHandler.new(File.open("tmp/application.log"))
end
```

### Nested Routes using `scope`

Scopes are a method in which you can nest routes under a common path. This prevents
the need for duplicating paths and allows a developer to easily change the parent
of a set of child paths.

```crystal
router MyApplicationRouter do
  scope "users" do
    root to: "Users#index"
    get ":id", to: "Users#show"
    delete ":id", to: "Users#destroy"
  end
end
```

#### Handlers within nested routes

Instances of [`HTTP::Handler`](https://crystal-lang.org/api/HTTP/Handler.html) can be
used within a `scope` block and will only apply to the subsequent routes within that scope.
It is important to note that the parent context’s handlers will also be used.

> Handlers will only apply to the routes specified below them, so be sure to place
> your handlers near the top of your scope.

```crystal
router MyApplicationRouter do
  scope "users" do
    use AuthorizationHandler.new
    root to: "Users#index"
    get ":id", to: "Users#show"
    delete ":id", to: "Users#destroy"
  end
end
```

#### Route Helper prefixes

When using [Helpers](#helpers), you may want a prefix to be appended so that you don’t have to
repeat it within each individual route. For example a scope with `helper_prefix: "users"`
containing a route with `helper: "show"` will generate a helper method of `users_show`.

```crystal
router MyApplicationRouter do
  scope "users", helper_prefix: "users" do
    use AuthorizationHandler.new
    get ":id", to: "Users#show", helper: "show"
  end
end
```

##### Caveats

When considering helpers within scopes you may want to use a longer form of the
helper to get a better name. You can pass a named tuple with the fields `name`,
`prefix`, and/or `suffix`.

```crystal
router MyApplicationRouter do
  scope "users", helper_prefix: "user" do
    use AuthorizationHandler.new
    get ":id", to: "Users#show", helper: { prefix: "show" }
  end
end
```

The above example will expand into `show_user` instead of `user_show`.

### Concerns – Reusable code in your routers

In some instances, you may want to create a pattern or concern that you wish
to repeat across scopes or resources in your router.

#### Defining a concern

To define a concern call `concern` with a `Symbol` for the name.

```crystal
router MyApplicationRouter do
  concern :authenticated do
    use Authentication.new
  end
end
```

#### Using concerns

Once a concern is defined you can call `implements` with a named concern from
anywhere in your router.

```crystal
router MyApplicationRouter do
  concern :authenticated do
    use Authentication.new
  end

  scope "users" do
    implements :authenticated
    get ":id"
  end
end
```

### Method Overrides

In some situations, certain environments may not support certain HTTP methods,
when in these environments, there are a few methods to force a different method
in the router. In either of the methods below, if you intend to pass a body, you
should be using the `POST` HTTP method when you make the request.

#### Header Overrides

If your client has the ability to set headers you can use the built-in ability to
pass the `X-HTTP-Method-Override: [METHOD]` method with the method you wish to invoke on
the router.

#### Parameter & Form Overrides

If your client has the ability to set headers you can use the
`Orion::Handlers::MethodOverrideParam` to pass a `_method=[METHOD]` parameter as
a query parameter or form field with the method you wish to invoke on the router.

```crystal
router MyRouter do
  use Orion::Handlers::MethodOverrideParam.new
  # ... routes
end
```

### Constraints - More advanced rules for your routes

Constraints can be used to further determine if a route is hit beyond just it’s path. Routes have some predefined constraints you can specify, but you can also
pass in a custom constraint.

#### Parameter constraints

When defining a route, you can pass in parameter constraints. The path params will
be checked against the provided regex before the route is chosen as a valid route.

```crystal
router MyApplicationRouter do
  get "users/:id", constraints: { id: /[0-9]{4}/ }
end
```

#### Format constraints

You can constrain the request to a certain format. Such as restricting
the extension of the URL to '.json'.

```crystal
router MyApplicationRouter do
  get "api/users/:id", format: "json"
end
```

#### Request Mime-Type constraints

You can constrain the request to a certain mime-type by using the `content_type` param
on the route. This will ensure that if the request has a body, it will provide the proper
content type.

```crystal
router MyApplicationRouter do
  put "api/users/:id", content_type: "application/json"
end
```

#### Response Mime-Type constraints

You can constrain the response to a certain mime-type by using the `accept` param
on the route. This is similar to the format constraint but allows clients to
specify the `Accept` header rather than the extension.

> Orion will automatically add mime-type headers for requests with no Accept header and
> a specified extension.

```crystal
router MyApplicationRouter do
  get "api/users/:id", accept: "application/json"
end
```

#### Combined Mime-Type constraints

You can constrain the request and response to a certain mime-type by using the `type` param
on the route. This will ensure that if the request has a body, it will provide the proper
content type. In addition, it will also validate that the client provides a proper
accept header for the response.

> Orion will automatically add mime-type headers for requests with no Accept header and
> a specified extension.

```crystal
router MyApplicationRouter do
  put "api/users/:id", type: "application/json"
end
```

#### Host constraints

You can constrain the request to a specific host by wrapping routes
in a `host` block. In this method, any routes within the block will be
matched at that constraint.

You may also choose to limit the request to a certain format. Such as restricting
the extension of the URL to '.json'.

```crystal
router MyApplicationRouter do
  host "example.com" do
    get "users/:id", format: "json"
  end
end
```

#### Subdomain constraints

You can constrain the request to a specific subdomain by wrapping routes
in a `subdomain` block. In this method, any routes within the block will be
matched at that constraint.

You may also choose to limit the request to a certain format. Such as restricting
the extension of the URL to '.json'.

```crystal
router MyApplicationRouter do
  subdomain "api" do
    get "users/:id", format: "json"
  end
end
```

#### Custom Constraints

You can also pass in your own constraints by just passing a class/struct that
implements the `Orion::Constraint` module.

```crystal
struct MyConstraint
  def matches?(req : HTTP::Request)
    true
  end
end

router MyApplicationRouter do
  constraint MyConstraint.new do
    get "users/:id", format: "json"
  end
end
```

### Route Helpers

Route helpers provide type-safe methods to generate paths and URLs to defined routes
in your application. By including the `Helpers` module on the router (i.e. `MyApplicationRouter::RouteHelpers`)
you can access any helper defined in the router by `{{name}}_path` to get its corresponding
route. In addition, when you have a `@context : HTTP::Server::Context` instance var,
you will also be able to access a `{{name}}_url` to get the full URL.

```crystal
router MyApplicationRouter do
  scope "users", helper_prefix: "user" do
    get "/new", to: "Users#new", helper: "new"
  end
end

class UsersController
  def new
  end
end

class MyController
  include MyApplicationRouter::RouteHelpers
  delegate request, response, to: @context

  def initialize(@context : HTTP::Server::Context)
  end

  def new
    File.open("new.html") { |f| IO.copy(f, response) }
  end

  def show
    user = User.find(request.path_params["id"])
    response.headers["Location"] = new_user_path
    response.status_code = 301
    response.close
  end
end
```

#### Making route helpers from your routes

In order to make a helper from your route, you can use the `helper` named argument in your route.

```crystal
router MyApplicationRouter do
  scope "users" do
    get "/new", to: "Users#new", helper: "new"
  end
end
```

#### Using route helpers in your code

As you add helpers they are added to the nested `Helpers` module of your router.
you may include this module anywhere in your code to get access to the methods,
or call them on the module directly.

*If `@context : HTTP::Server::Context` is present in the class, you will also be
able to use the `{helper}_url` versions of the helpers.*

```crystal
router MyApplicationRouter do
  resources :users
end

class User
  include MyApplicationRouter::RouteHelpers

  def route
    user_path user_id: self.id
  end
end

puts MyApplicationRouter::RouteHelpers.users_path
```

## Contributing

1.  Fork it [https://github.com/&lt;your-github-name&gt;/orion/fork](https://github.com/<your-github-name>/orion/fork)

2.  Create your feature branch (git checkout -b my-new-feature)

3.  Commit your changes (git commit -am 'Add some feature')

4.  Push to the branch (git push origin my-new-feature)

5.  Create a new Pull Request

## Contributors

-   [Jason Waldrip (jwaldrip)](https://github.com/jwaldrip) - creator, maintainer
