defmodule FunPipelineCast do
  use Flowex.Pipeline

  pipe :add_one
  pipe :mult_by_two
  pipe :minus_three
  pipe :print_result

  defstruct number: nil, pid: nil

  def add_one(struct, _opts) do
    new_number = struct.number + 1
    %{struct | number: new_number}
  end

  def mult_by_two(struct, _opts) do
    new_number = struct.number * 2
    %{struct | number: new_number}
  end

  def minus_three(struct, _opts) do
    new_number = struct.number - 3
    %{struct | number: new_number}
  end

  def print_result(struct, _opts) do
    send(struct.pid, struct)
    struct
  end
end
