# faastruby-rpc

Wrapper to make it easy to call FaaStRuby functions.

#### What is FaaStRuby?
FaaStRuby is a serverless platform built for Ruby developers.

* [Tutorial](https://faastruby.io/getting-started)

## Calling functions from within a function (RPC calls)

To call another function you must first require it on the top of `handler.rb`, passing a string that will be converted to a constant. You then use the constant to call the function and get its response.

To call the function, use the method `call`. Here is an example.

```ruby
require_function 'hello-world', as: 'HelloWorld'
def handler(event)
  hello = HelloWorld.call # Async call
  hello.class #=> FaaStRuby::RPC::Function
  hello.returned? #=> false # READ BELOW TO UNDERSTAND
  puts hello #=> Hello, World! - Will block and wait until the response arrives
  returned_value = hello.value #=> 'Hello, World!' - Block, wait for the response and assign to variable 'returned_value'
  hello.returned? #=> true # READ BELOW TO UNDERSTAND
  hello.code #=> 200 - The status code
  hello.headers #=> {"content-type"=>"text/plain", "x-content-type-options"=>"nosniff", "connection"=>"close", "content-length"=>"5"} - The response headers
  render text: hello
end
```
The biggest problem with serverless applications is the latency resultant of multiple calls to different functions. This is called Tail Latency.
To minimize this problem, `faastruby-rpc` will handle the request to other functions in an async fashion.
You should design your application with that in mind. For example, you can design your application so the external function calls are done early in the program execution and perform other tasks while you wait for the response.

In the example above, `hello = HelloWorld.call` will issue a non-blocking HTTP request in a separate thread to the called function's endpoint, assign it to a variable and continue execution. When you need the return value from that function, just use the variable. If you call the variable before the request is completed, the execution will block until an answer is received from the external function. To minimize tail latency, just design your application around those async calls.

If at any point you need to know if the external function call already returned without blocking the execution of your program, use the method `returned?`. So in the example above, `hello.returned?` will be false until the request is fulfilled.

## Passing arguments to the called function

Say you have the following function named `echo`:

```ruby
# Note the required keyword argument 'name:'
def handler(event, name:)
  render text: name
end
```

If you want to call this function in another function, you can simply pass the argument within `call`:

```ruby
require_function 'echo', as: 'Echo'
def handler(event)
  name = Echo.call(name: 'John Doe') # Async call
  render text: "Hello, #{name}!" # calling 'name' will block until Echo returns
end
```
You can use positional or keyword arguments when calling external functions, as long as the external function's `handler` method is defined with matching arguments.

This gem is already required when you run your functions in FaaStRuby, or using `faastruby server`.

## Running code when the invoked function responds
If you pass a block when you call another function, the block will execute as soon as the response arrives. For example:

```ruby
require_function 'echo', as: 'Echo'
def handler(event)
  name = Echo.call(name: 'john doe') do |response|
    # response.body      #=> "john doe"
    # response.code      #=> 200
    # response.headers   #=> {"content-type"=>"text/plain",...}
    # What you return from the block will be the value of `name` or `name.body`
    response.body.capitalize
  end
  render text: "Hello, #{name}!" # Will render 'John Doe'
end
```

## Handling errors

By default, an exception is raised if the invoked function HTTP status code is greater or equal to 400. This is important to make your functions easier to debug, and you will always know what to expect from that function call.

To disable this behaviour, pass `raise_errors: false` when requiring the function. For example:

```ruby
require_function 'paulo/hello-world', as: 'HelloWorld', raise_errors: false
```

## Stubbing RPC calls in your function tests
If you are testing a function that required another one, you likely will want to fake that call. To do that, use the following test helper:

```ruby
# This will make it fake the calls to 'hello-world'
# and return the values you pass in the block.
require 'faastruby-rpc/test_helper'

FaaStRuby::RPC.stub_call('hello-world') do |response|
  response.body = "hello, world!"
  response.code = 200
  response.headers = {'A-Header' => 'foobar'}
end
```
