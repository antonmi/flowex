defmodule ModulePipeline do
  use Flowex.Pipeline

  defstruct [:number, :a, :b, :c]

  pipe AddOne, 1
  pipe MultByTwo, 3
  pipe :do_nothing, 2
  pipe MinusThree, 2
  error_pipe IfError, 3

  def do_nothing(struct, _opts) do
    struct
  end
end

#pipes
defmodule AddOne do
  defstruct [:number]

  def init(opts) do
    %{opts | a: :add_one}
  end

  def call(%{number: number}, %{a: a}) do
    %{number: number + 1, a: a}
  end
end

defmodule MultByTwo do
  defstruct [:number]

  def init(opts) do
    %{opts | b: :mult_by_two}
  end

  def call(%{number: number}, %{b: b}) do
    %{number: number * 2, b: b}
  end
end

defmodule MinusThree do
  defstruct [:number]

  def init(opts) do
    %{opts | c: :minus_three}
  end

  def call(%{number: number}, %{c: c}) do
    %{number: number - 3, c: c}
  end
end

defmodule IfError do
  defstruct [:number]

  def init(opts), do: opts

  def call(error, %{number: _number}, _opts) do
    %{number: error}
  end
end
