defmodule FunPipeline do
  use Flowex.Pipeline

  defstruct number: nil, a: nil, b: nil, c: nil

  pipe :init_data, 1
  pipe :add_one, 2
  pipe :multiply_by_2, 2

  def init_data(struct, opts) do
    %{struct | number: 1, a: opts.a}
  end

  def add_one(struct, opts) do
    # Process.sleep(1000)
    # IO.inspect("add_one: #{inspect self()}")
    new_number = struct.number + 1
    %{struct | number: new_number, b: opts.b}
  end

  def multiply_by_2(struct, opts) do
    # Process.sleep(1000)
    # IO.inspect("multiply_by_2: #{inspect self()}")
    new_number = struct.number * 2
    %{struct | number: new_number, c: opts.c}
  end
end
