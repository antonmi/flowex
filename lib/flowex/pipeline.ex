defmodule Flowex.Pipeline do
  defstruct module: nil, in_name: nil, out_name: nil, sup_pid: nil

  defmacro pipe(atom, count \\ 1) do
    quote do
      @pipes unquote({atom, count})
    end
  end

  defmacro __using__(_args) do
    quote do
      import Flowex.Pipeline

      Module.register_attribute __MODULE__, :pipes, accumulate: true
      @before_compile Flowex.Pipeline

      def start(opts \\ %{}) do
        Flowex.PipelineBuilder.start(__MODULE__, opts)
      end

      def stop(%Flowex.Pipeline{sup_pid: sup_pid}) do
        Flowex.PipelineBuilder.stop(sup_pid)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def pipes, do: Enum.reverse(@pipes)

      def run(%Flowex.Pipeline{in_name: in_name, out_name: out_name}, struct = %__MODULE__{}) do
        ip = %Flowex.IP{struct: struct, requester: self()}
        GenServer.cast(out_name, {in_name, ip})

        receive do
          ip -> ip.struct
        end
      end
    end
  end
end
