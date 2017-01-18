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

  def mult_by_two(struct, opts) do
    new_number = struct.number * 2
    %{struct | number: new_number, b: opts.b}
  end

  def minus_three(struct, opts) do
    new_number = struct.number - 3
    %{struct | number: new_number, c: opts.c}
  end
end
