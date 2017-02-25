defmodule ModulePipeline do
  use Flowex.Pipeline

  defstruct number: nil, a: nil, b: nil, c: nil

  pipe AddOne, 1
  pipe MultByTwo, 3
  pipe MinusThree, 2
  error_pipe IfError, 3
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

  def call(error, struct, _opts) do
    %{struct | number: error}
  end
end
