defmodule FunPipeline do
  use Flowex.Pipeline

  pipe :add_one
  pipe :mult_by_two
  pipe :minus_three

  defstruct number: nil, a: nil, b: nil, c: nil

  def add_one(%{number: number}, %{a: a}) do
    %{number: number + 1, a: a}
  end

  def mult_by_two(%{number: number}, %{b: b}) do
    %{number: number * 2, b: b}
  end

  def minus_three(%{number: number}, %{c: c}) do
    %{number: number - 3, c: c}
  end
end
