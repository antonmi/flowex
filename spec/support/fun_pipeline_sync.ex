defmodule FunPipelineSync do
  use Flowex.Sync.Pipeline

  pipe :add_one, opts: %{o1: 1}
  pipe :mult_by_two, opts: %{o2: 2}
  pipe :minus_three, opts: %{o3: 3}

  defstruct number: nil, a: nil, b: nil, c: nil

  def add_one(%{number: number}, %{a: a, o1: o1}) do
    %{number: number + 1, a: {a, o1}}
  end

  def mult_by_two(%{number: number}, %{b: b, o2: o2}) do
    %{number: number * 2, b: {b, o2}}
  end

  def minus_three(%{number: number}, %{c: c, o3: o3}) do
    %{number: number - 3, c: {c, o3}}
  end
end
