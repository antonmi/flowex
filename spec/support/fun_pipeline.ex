defmodule FunPipeline do
  use Flowex.Pipeline

  defstruct number: nil, a: nil, b: nil, c: nil

  pipe :add_one, 1
  pipe :mult_by_two, 1
  pipe :minus_three, 1

  def add_one(struct, opts) do
    # Process.sleep(1000)
    # IO.inspect("add_one: #{inspect self()}")
    new_number = struct.number + 1
    %{struct | number: new_number, a: opts.a}
  end

  def mult_by_two(struct, opts) do
    # Process.sleep(1000)
    # IO.inspect("multiply_by_2: #{inspect self()}")
    new_number = struct.number * 2
    %{struct | number: new_number, b: opts.b}
  end

  def minus_three(struct, opts) do
    new_number = struct.number - 3
    %{struct | number: new_number, c: opts.c}
  end
end
