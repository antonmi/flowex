defmodule FunPipelineCast do
  use Flowex.Pipeline

  pipe :add_one
  pipe :mult_by_two
  pipe :minus_three
  pipe :print_result

  defstruct number: nil, pid: nil

  def add_one(%{number: number}, _opts) do
    %{number: number + 1}
  end

  def mult_by_two(%{number: number}, _opts) do
    %{number: number * 2}
  end

  def minus_three(%{number: number}, _opts) do
    %{number: number - 3}
  end

  def print_result(%{number: number, pid: pid}, _opts) do
    send(pid, number)
  end
end
