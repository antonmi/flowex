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

      import Supervisor.Spec

      @before_compile Flowex.Pipeline

      def start(opts \\ %{}) do
        {:ok, sup_pid} = Flowex.Supervisor.start_link(__MODULE__)
        [{{Flowex.Producer, _, _}, in_producer, :worker, [Flowex.Producer]}] = Supervisor.which_children(sup_pid)

        last_pids = pipes()
        |> Enum.reduce([in_producer], fn({atom, count}, prev_pids) ->
          pids = (1..count)
          |> Enum.map(fn(i) ->
            {:ok, pid} = case Atom.to_char_list(atom) do
              ~c"Elixir." ++ _ -> init_module_pipe(sup_pid, {atom, opts}, prev_pids)
              _ ->  init_function_pipe(sup_pid, {atom, opts}, prev_pids)
            end
            pid
          end)
          pids
        end)

        worker_spec = worker(Flowex.Consumer, [last_pids], [id: {Flowex.Consumer, nil, make_ref()}])
        {:ok, out_consumer} = Supervisor.start_child(sup_pid, worker_spec)

        Experimental.GenStage.demand(in_producer, :forward)
        %Flowex.Pipeline{module: __MODULE__, in_pid: in_producer, out_pid: out_consumer, sup_pid: sup_pid}
      end

      def stop(%Flowex.Pipeline{sup_pid: sup_pid}) do
        Supervisor.which_children(sup_pid)
        |> Enum.each(fn({id, pid, :worker, [_]}) ->
          Supervisor.terminate_child(sup_pid, id)
        end)
        Supervisor.stop(sup_pid)
      end

      defp init_function_pipe(sup_pid, {function, opts}, prev_pids) do
        worker_spec = worker(Flowex.Stage, [{__MODULE__, function, opts, prev_pids}], [id: {__MODULE__, function, make_ref()}])
        Supervisor.start_child(sup_pid, worker_spec)
      end

      defp init_module_pipe(sup_pid, {module, opts}, prev_pids) do
        opts = module.init(opts)
        worker_spec = worker(Flowex.Stage, [{module, :call, opts, prev_pids}], [id: {module, :call, make_ref()}])
        Supervisor.start_child(sup_pid, worker_spec)
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
