# faastruby-rpc

Wrapper to make it easy to call FaaStRuby functions.

#### What is FaaStRuby?
FaaStRuby is a serverless platform built for Ruby developers.

* [Tutorial](https://faastruby.io/tutorial.html)

## Calling functions from within a function

To call a function, use the helper method `invoke`:

```ruby
# You need the function path, which is WORKSPACE_NAME/FUNCTION_NAME
function = 'paulo/hello'
# Invoke the function the get the result
result = invoke(function).call
# Or passing arguments:
result = invoke(function).with('Paulo', likes_ruby: true)
```

`result` is a Struct with the following attributes:
* result.body - The response body from the function you called
* result.code - The HTTP status code returned by the function
* result.headers - The headers returned by the functions

The arguments in `with` are passed as arguments to your function (after the `event`). You can capture them with positional arguments, keyword arguments or just a generic `*args` if you want to have the flexibility of sending a variable number of arguments.

Here is the source code of `paulo/hello`:

```ruby
def handler event, name = nil
  response = name ? "Hello, #{name}!" : 'Hello, there!'
  render text: response
end
```

When you call `invoke`, a request is sent with the following properties:
* method: POST
* header `Content-Type: application/json`
* header `Faastruby-Rpc: true`
* body: JSON array

`invoke` is just a helper to the following method:
```ruby
# Calling a function that way defaults to method=GET
FaaStRuby::RPC::Function.new("FUNCTION_PATH").call(body: nil, query_params: {}, headers: {}, method: 'get')
```

This gem is already required when you run your functions in FaaStRuby, or using `faastruby server`.

## Handling errors

By default, an exception is raised if the invoked function HTTP status code is greater than 400. This is important to make your functions easier to debug, and you will always know what to expect from that function call.

To disable this behaviour, pass `raise_errors: false` to the `invoke` method, or to `FaaStRuby::RPC::Function.new`. Example:

```ruby
invoke('paulo/hello', raise_errors: false).call
# or
FaaStRuby::RPC::Function.new("paulo/hello", raise_errors: false).call(body: nil)
```

## Stubbing invoke() in your function tests
If you are testing a function that invokes another one, you likely will want to fake that call. To do that, use the following test helper:

```ruby
# This will cause invoke('paulo/hello-world')... to fake the call to
# 'paulo/hello-world' and instead return the values you pass in the block.
require 'faastruby-rpc/test_helper'

FaaStRuby::RPC.stub_call('paulo/hello-world') do |response|
  response.body = "hello, world!"
  response.code = 200
  response.headers = {'A-Header' => 'foobar'}
end
```
