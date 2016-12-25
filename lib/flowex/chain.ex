defmodule Flowex.Chain do
  defstruct module: nil, in_pid: nil, out_pid: nil, sup_pid: nil

  defmacro component(function, count \\ 1) do
    quote do
      @components unquote({function, count})
    end
  end

  defmacro __using__(_args) do
    quote do
      Module.register_attribute __MODULE__, :components, accumulate: true

      import Flowex.Chain
      use GenServer

      @before_compile Flowex.Chain

      def init do
        {:ok, in_producer} = Experimental.GenStage.start_link(Flowex.Producer, nil)

        last_pids = components()
        |> Enum.reduce([in_producer], fn({function, count}, prev_pids) ->
          pids = (1..count)
          |> Enum.map(fn(i) ->
            {:ok, pid} = Experimental.GenStage.start_link(Flowex.Component, {__MODULE__, function, prev_pids})
            pid
          end)
          pids
        end)

        {:ok, out_consumer} = Experimental.GenStage.start_link(Flowex.Consumer, last_pids)

        Experimental.GenStage.demand(in_producer, :forward)

        %Flowex.Chain{module: __MODULE__, in_pid: in_producer, out_pid: out_consumer}
      end

      def run(%Flowex.Chain{in_pid: in_pid, out_pid: out_pid}, data) do
        ip = %Flowex.IP{data: data, requester: self()}
        GenServer.cast(out_pid, {in_pid, ip})
        receive do
          ip -> ip.data
        end
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def components, do: Enum.reverse(@components)
    end
  end
end
