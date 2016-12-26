defmodule Flowex.Pipeline do
  defstruct module: nil, in_pid: nil, out_pid: nil, sup_pid: nil

  defmacro pipe(atom, count \\ 1) do
    quote do
      @pipes unquote({atom, count})
    end
  end

  defmacro __using__(_args) do
    quote do
      Module.register_attribute __MODULE__, :pipes, accumulate: true

      import Flowex.Pipeline
      use GenServer

      @before_compile Flowex.Pipeline

      def start(opts \\ %{}) do
        {:ok, in_producer} = Flowex.Producer.start_link(nil)

        last_pids = pipes()
        |> Enum.reduce([in_producer], fn({atom, count}, prev_pids) ->
          pids = (1..count)
          |> Enum.map(fn(i) ->
            {:ok, pid} = case Atom.to_char_list(atom) do
              ~c"Elixir." ++ _ -> init_module_pipe({atom, opts}, prev_pids)
              _ ->  init_function_pipe({atom, opts}, prev_pids)
            end
            pid
          end)
          pids
        end)

        {:ok, out_consumer} = Flowex.Consumer.start_link(last_pids)
        Experimental.GenStage.demand(in_producer, :forward)
        %Flowex.Pipeline{module: __MODULE__, in_pid: in_producer, out_pid: out_consumer}
      end

      defp init_function_pipe({function, opts}, prev_pids) do
        Flowex.Stage.start_link({__MODULE__, function, opts, prev_pids})
      end

      defp init_module_pipe({module, opts}, prev_pids) do
        opts = module.init(opts)
        Flowex.Stage.start_link({module, :call, opts, prev_pids})
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

#
