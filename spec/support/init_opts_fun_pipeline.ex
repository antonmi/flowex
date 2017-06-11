defmodule InitOptsFunPipeline do
  use Flowex.Pipeline

  defstruct [:from_start, :from_init, :from_opts]
  pipe :component, opts: %{from_opts: 3}, count: 2

  def init(opts), do: Map.put(opts, :from_init, 2)

  def component(_data, opts), do: opts
end


defmodule InitOptsModulePipeline do
  use Flowex.Pipeline

  defstruct [:from_start, :from_init, :from_opts, :component_init]
  pipe OptComponent, opts: %{from_opts: 3}, count: 2

  def init(opts), do: Map.put(opts, :from_init, 2)
end


defmodule OptComponent do
  defstruct []

  def init(opts), do: Map.put(opts, :component_init, 4)
  def call(_data, opts), do: opts
end
