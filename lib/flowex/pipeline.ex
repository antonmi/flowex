defmodule Flowex.Pipeline do
  defstruct module: nil, in_pid: nil, out_pid: nil, sup_pid: nil

  defmacro pipe(function, count \\ 1) do
    quote do
      @pipes unquote({function, count})
    end
  end

  defmacro __using__(_args) do
    quote do
      Module.register_attribute __MODULE__, :pipes, accumulate: true

      import Flowex.Pipeline
      use GenServer

      @before_compile Flowex.Pipeline

      def start(opts \\ %{}) do
        {:ok, in_producer} = Experimental.GenStage.start_link(Flowex.Producer, nil)

        last_pids = pipes()
        |> Enum.reduce([in_producer], fn({function, count}, prev_pids) ->
          pids = (1..count)
          |> Enum.map(fn(i) ->
            {:ok, pid} = Experimental.GenStage.start_link(Flowex.Stage, {__MODULE__, function, opts, prev_pids})
            pid
          end)
          pids
        end)

        {:ok, out_consumer} = Experimental.GenStage.start_link(Flowex.Consumer, last_pids)
        Experimental.GenStage.demand(in_producer, :forward)
        %Flowex.Pipeline{module: __MODULE__, in_pid: in_producer, out_pid: out_consumer}
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def pipes, do: Enum.reverse(@pipes)

      def run(%Flowex.Pipeline{in_pid: in_pid, out_pid: out_pid}, struct = %__MODULE__{}) do
        ip = %Flowex.IP{struct: struct, requester: self()}
        GenServer.cast(out_pid, {in_pid, ip})
        receive do
          ip -> ip.struct
        end
      end
    end
  end
end
