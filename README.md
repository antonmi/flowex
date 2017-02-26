# Flowex
[![Build Status](https://travis-ci.org/antonmi/flowex.svg?branch=master)](https://travis-ci.org/antonmi/flowex)
[![Hex.pm](https://img.shields.io/hexpm/v/flowex.svg?style=flat-square)](https://hex.pm/packages/flowex)

## Railway Flow-Based Programming with Elixir GenStage.
#### Flowex is a set of abstractions build on top Elixir GenStage which allows writing program with [Flow-Based Programming](https://en.wikipedia.org/wiki/Flow-based_programming) paradigm.
I would say it is a mix of FBP and so-called [Railway Oriented Programming (ROP)](http://fsharpforfunandprofit.com/rop/) approach.

Flowex DSL allows you to easily create "pipelines" of Elixir GenStages.
#### Dedicated to my lovely girlfriend Chryścina.

## Contents
- [Installation](#installation)
- [A simple example to get the idea](#a-simple-example-to-get-the-idea)
- [More complex example for understanding interface](#more-complex-example-for-understanding-interface)
- [Flowex magic!](#flowex-magic!)
- [Run the pipeline](#run-the-pipeline)
- [How it works](#how-it-works)
- [Error handling](#error-handling)
- [Synchronous and asynchronous calls](#synchronous-and-asynchronous-calls)
- [Bottlenecks](#bottlenecks)
- [Module pipelines](#module-pipelines)
- [Contributing](#contributing)

## Installation
Just add `flowex` as dependency to the `mix.exs` file.

## A simple example to get the idea
Let's consider a simple program which receives a number as an input, then adds one, then multiplies the result by two and finally subtracts 3.

```elixir
defmodule Functions do
  def add_one(number), do: number + 1
  def mult_by_two(number), do: number * 2
  def minus_three(number), do: number - 3
end

defmodule MainModule do
  def run(number) do
    number
    |> Functions.add_one
    |> Functions.mult_by_two
    |> Functions.minus_three
  end
end
```
So the program is a pipeline of functions with the same interface. The functions are very simple in the example.

In the real world they can be something like `validate_http_request`, `get_user_from_db`, `update_db_from_request` and `render_response`.
Furthermore, each of the function can potentially fail. But for getting the idea let's stick the simplest example.

FBP defines applications as networks of "black box" processes, which exchange data across predefined connections by message passing.

To satisfy the FBP approach we need to place each of the function into a separate process. So the number will be passed from 'add_one' process to 'mult_by_two' and then 'minus_three' process which returns the final result.

That, in short, is the idea of Flowex!

## More complex example for understanding interface
Let's define a more strict interface for our function. Flowex uses the same approach as [Plug](https://github.com/elixir-lang/plug).
So each of the function must receive a predefined struct as a first argument and return the struct of the same type:

```elixir
def add_one(struct, opts) do
  new_number = struct.number + 1
  %{struct | number: new_number, a: opts.a}
end
```
The function receives a structure with `number` and `a` fields and returns modified structure or the same type.
The second argument is a set of options and will be described later.
Let's rewrite the whole `Functions` module in the following way:
```elixir
defmodule Functions do
  defstruct number: nil, a: nil, b: nil, c: nil

  def add_one(struct, opts) do
    new_number = struct.number + 1
    %{struct | number: new_number, a: opts.a}
  end

  def mult_by_two(struct, opts) do
    new_number = struct.number * 2
    %{struct | number: new_number, b: opts.b}
  end

  def minus_three(struct, opts) do
    new_number = struct.number - 3
    %{struct | number: new_number, c: opts.c}
  end
end
```
The code is more complex but more solid. The module defines three functions with the same interface.
We also defined as struct `%Functions{}` which defines a data-structure being passed to the functions.

The main module may look like:
```elixir
defmodule MainModule do
  def run(number) do
    opts = %{a: 1, b: 2, c: 3}
    %Functions{number: number}
    |> Functions.add_one(opts)
    |> Functions.mult_by_two(opts)
    |> Functions.minus_three(opts)
  end
end
```

## Flowex magic!
Let's add a few lines at the beginning.
```elixir
defmodule FunPipeline do
  use Flowex.Pipeline

  pipe :add_one
  pipe :mult_by_two
  pipe :minus_three

  defstruct number: nil, a: nil, b: nil, c: nil

  def add_one(struct, opts) do
    new_number = struct.number + 1
    %{struct | number: new_number, a: opts.a}
  end

  # mult_by_two and minus_three definitions skipped
end
```
We also renamed the module to `FunPipeline` because we are going to create "Flowex pipeline".
`Flowex.Pipeline` extend our module, so we have:
- `pipe` macro to define which function evaluation should be placed into separate GenStage;
- `error_pipe` macro to define function which will be called if error occurs;
- `start` and `stop` functions to create and destroy pipelines;
- `call` function to run pipeline computations synchronously.
- `cast` function to run pipeline computations asynchronously.

Let's start a pipeline:
```elixir
opts = %{a: 1, b: 2, c: 3}

pipeline = FunPipeline.start(opts)

#returns
%Flowex.Pipeline{in_name: :"Flowex.Producer_#Reference<0.0.7.504>",
 module: FunPipeline, out_name: :"Flowex.Consumer_#Reference<0.0.7.521>",
 sup_pid: #PID<0.136.0>}
```
What happened:
- Three GenStages were started - one for each of the function in pipeline. Each of GenStages is `:producer_consumer`;
- One additional GenStage for error processing is started (it is also `:producer_consumer`);
- Runs 'producer' and 'consumer' GenStages for input and output;
- All the components are placed under Supervisor.

The next picture shows what the 'pipeline' is.
![alt text](figures/fun_pipeline.png "FunPipeline")

The `start` function returns a `%Flowex.Pipeline{}` struct with the following fields:
- module - the name of the module
- in_name - unique name of 'producer';
- out_name - unique name of 'consumer';
- sup_pid - pid of the pipeline supervisor

Note, we have passed options to `start` function. This options will be passed to each function of the pipeline as a second argument.

## Run the pipeline
One can run calculations in pipeline synchronously and asynchronously:
- `call` function to run pipeline computations synchronously.
- `cast` function to run pipeline computations asynchronously.

`FunPipeline.call/2` function receive a `%Flowex.Pipeline{}` struct as a first argument and must receive a `%FunPipeline{}` struct as a second one.
The `call` function returns a %FunPipeline{} struct.

```elixir
FunPipeline.call(pipeline, %FunPipeline{number: 2})
# returns
%FunPipeline{a: 1, b: 2, c: 3, number: 3}
```
As expected, pipeline returned `%FunPipeline{}` struct with `number: 3`. `a`, `b` and `c` were set from options.

If you don't care about the result, you should use `cast/2` function to run and forget.
```elixir
FunPipeline.cast(pipeline, %FunPipeline{number: 2})
# returns
:ok
```

## Run via client
Another way is using `Flowex.Client` module which implements GenServer behavior.
The `Flowex.Client.start\1` function receives pipeline struct as an argument.
Then you can use `call/2` function or `cast/2`. See example below:
```elixir
{:ok, client_pid} = Flowex.Client.start(pipeline)

Flowex.Client.call(client_pid, %FunPipeline{number: 2})
# returns
%FunPipeline{a: 1, b: 2, c: 3, number: 3}

#or
Flowex.Client.cast(client_pid, %FunPipeline{number: 2})
# returns
:ok
```
## How it works
The following figure demonstrates the way data follows:
![alt text](figures/pipeline_with_client.png "How it works")
Note: `error_pipe` is not on the picture in order to save place.

The things happen when you call `Flowex.Client.call` (synchronous):
- `self` process makes synchronous call to the client gen_server with `%FunPipeline{number: 2}` struct;
- the client makes synchronous call 'FunPipeline.call(pipeline, %FunPipeline{number: 2})';
- the struct is wrapped into `%Flowex.IP{}` struct and begins its asynchronous journey from one GenStage to another;
- when the consumer receives the Information Packet (IP), it sends it back to the client which sends it back to the caller process.

The things happen when you `cast` pipeline (asynchronous):
- `self` process makes `cast` call to the client and immediately receives `:ok`
- the client makes `cast` to pipeline;
- the struct is wrapped into `%Flowex.IP{}` struct and begins its asynchronous journey from one GenStage to another;
- consumer does not send data back, because this is `cast`

## Error handling
What happens when error occurs in some pipe?

The pipeline behavior is like Either monad. If everything ok, each 'pipe' function will be called one by one and result data will skip the 'error_pipe'.
But if error happens, for example, in the first pipe, the `:mult_by_two` and `:minus_three` functions will not be called.
IP will bypass to the 'error_pipe'. If you don't specify 'error_pipe' flowex will add the default one:
```elixir
def handle_error(error, _struct, _opts) do
  raise error
end
```
which just raises an exception.

To specify the 'error' function use `error_pipe` macro:
```elixir
defmodule FunPipeline do
  use Flowex.Pipeline
  # ...
  error_pipe :if_error


  def if_error(error, struct, opts) do
    # error is %Flowex.PipeError{} structure
    # with :message, :pipe, and :struct fields
    %{struct | number: :oops}
  end
  #...
end
```
You can specify only one error_pipe!
Note: The 'error_pipe' function accepts three arguments.
The first argument is a `%Flowex.PipeError{}` structure which has the following fields:
- `:message` - error message;
- `:pipe` - is `{module, function, opts}` tuple containing info about the pipe where error occured;
- `:struct` - the input of the pipe.

## Synchronous and asynchronous calls
Note, that `call` function on pipeline module or `Flowex.Client` is synchronous. While communication inside the pipeline is asynchronous:
![alt text](figures/pipeline_sync_async.png "Sync and async")
One might think that there is no way to effectively use the pipeline via `call/2` method.

That's not true!

In order to send a large number of IP's and process them in parallel one can use several clients connected to the pipeline:
![alt text](figures/many_clients.png "Group of clients")

## Bottlenecks
Each component of pipeline takes a some to finish IP processing. One component does simple work, another can process data for a long time.
So if several clients continuously push data they will stack before the slowest component. And data processing speed will be limited by that component.

Flowex has a solution! One can define a number of execution processes for each component.
```elixir
defmodule FunPipeline do
  use Flowex.Pipeline

  pipe :add_one, 1
  pipe :mult_by_two, 3
  pipe :minus_three, 2
  error_pipe :if_error, 2

  # ...
end
```
And the pipeline will look like on the figure below:
![alt text](figures/complex_pipeline.png "Group of clients")


## Module pipelines
One can create reusable 'pipe' - module which implements init and call functions.
```elixir
defmodule ModulePipeline do
  use Flowex.Pipeline

  defstruct number: nil, a: nil, b: nil, c: nil

  pipe AddOne, 1
  pipe MultByTwo, 3
  pipe MinusThree, 2
  error_pipe IfError, 2
end

#pipes

defmodule AddOne do
  def init(opts) do
    %{opts | a: :add_one}
  end

  def call(struct, opts) do
    new_number = struct.number + 1
    %{struct | number: new_number, a: opts.a}
  end
end

defmodule MultByTwo do
  def init(opts) do
    %{opts | b: :mult_by_two}
  end

  def call(struct, opts) do
    new_number = struct.number * 2
    %{struct | number: new_number, b: opts.b}
  end
end

defmodule MinusThree do
  def init(opts) do
    %{opts | c: :minus_three}
  end

  def call(struct, opts) do
    new_number = struct.number - 3
    %{struct | number: new_number, c: opts.c}
  end
end

defmodule IfError do
  def init(opts) do
    %{opts | c: :minus_three}
  end

  def call(_error, struct, _opts) do
    %{struct | number: :oops}
  end
end
```

Of course, one can combine module and functional 'pipes'!

## Contributing
#### Contributions are welcome and appreciated!

Request a new feature by creating an issue.

Create a pull request with new features or fixes.

Flowex is tested using ESpec. So run:
```sh
mix espec
```
