defmodule ModulePipelineSync do
  use Flowex.Sync.Pipeline

  defstruct [:number, :a, :b, :c]

  pipe AddOne, count: 1, opts: %{o1: 1}
  pipe MultByTwo, count: 3, opts: %{o1: 2}
  pipe :do_nothing, count: 2
  pipe MinusThree, count: 2, opts: %{o1: 3}
  error_pipe IfError, count: 3

  def do_nothing(struct, _opts) do
    struct
  end
end
