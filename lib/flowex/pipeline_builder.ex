defmodule Flowex.PipelineBuilder do
  import Supervisor.Spec

  def start(pipeline_module, opts) do
    {:ok, sup_pid} = Flowex.Supervisor.start_link(pipeline_module)
    [{producer_name, _in_producer, :worker, [Flowex.Producer]}] = Supervisor.which_children(sup_pid)

    last_names = pipeline_module.pipes()
    |> Enum.reduce([producer_name], fn({atom, count}, prev_pids) ->
      (1..count)
      |> Enum.map(fn(i) ->
        case Atom.to_char_list(atom) do
          ~c"Elixir." ++ _ -> init_module_pipe(sup_pid, {atom, opts}, prev_pids)
          _ ->  init_function_pipe(sup_pid, {pipeline_module, atom, opts}, prev_pids)
        end
      end)
    end)

    consumer_name = String.to_atom("Flowex.Consumer_#{inspect make_ref()}")
    worker_spec = worker(Flowex.Consumer, [last_names, [name: consumer_name]], [id: consumer_name])
    {:ok, _out_consumer_pid} = Supervisor.start_child(sup_pid, worker_spec)

    %Flowex.Pipeline{module: pipeline_module, in_name: producer_name, out_name: consumer_name, sup_pid: sup_pid}
  end

  def stop(sup_pid) do
    Supervisor.which_children(sup_pid)
    |> Enum.each(fn({id, pid, :worker, [_]}) ->
      Supervisor.terminate_child(sup_pid, id)
    end)
    Supervisor.stop(sup_pid)
  end

  defp init_function_pipe(sup_pid, {pipeline_module, function, opts}, prev_pids) do
    name = String.to_atom("#{__MODULE__}.#{function}_#{inspect make_ref()}")
    worker_spec = worker(Flowex.Stage,
                         [{pipeline_module, function, opts, prev_pids}, [name: name]],
                         [id: name])
    {:ok, _pid} = Supervisor.start_child(sup_pid, worker_spec)
    name
  end

  defp init_module_pipe(sup_pid, {module, opts}, prev_pids) do
    opts = module.init(opts)
    name = String.to_atom("#{module}.call_#{inspect make_ref()}")
    worker_spec = worker(Flowex.Stage,
                         [{module, :call, opts, prev_pids}, [name: name]],
                         [id: name])
    {:ok, _pid} = Supervisor.start_child(sup_pid, worker_spec)
    name
  end
end
