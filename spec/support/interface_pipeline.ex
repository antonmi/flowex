defmodule InterfacePipeline do
  use Flowex.Pipeline
  defstruct [:x, :y, :a, :b, :foo, :p, :q, :ok, :z]

  pipe C1
  pipe C2
  pipe :c3

  def c3(%{foo: foo, x: x, y: y}, _opts) do
    %{p: "#{foo} - #{x}", q: y}
  end
end

defmodule C1 do
  defstruct [:x, :y, :a, :b]

  def init(opts), do: opts

  def call(%{x: x, y: y}, _opts) do
    %{a: x + y, b: x * y, z: :z}
  end
end

defmodule C2 do
  defstruct [:a, :x, :foo]

  def init(opts), do: opts

  def call(%{a: a, x: x}, _opts) do
    %{foo: "Hello", x: x + a}
  end
end

# README example
defmodule DataAvailable do
  use Flowex.Pipeline

  defstruct [:top, :c1, :foo]

  pipe Component1
  pipe :component2
  pipe Component3

  def component2(%__MODULE__{top: top}, _opts) do
    %{top: top + 2, c3: 2}
  end
end

defmodule Component1 do
  defstruct [:top, :c1]
  def init(opts), do: opts

  def call(%__MODULE__{c1: c1, top: top}, _opts) do
    %{top: top + c1, bar: :baz}
  end
end

defmodule Component3 do
  defstruct [:c3, :top]
  def init(opts), do: opts

  def call(%__MODULE__{c3: c3, top: top}, _opts) do
    %{top: top + c3, c3: top - c3, foo: :set_foo}
  end
end
