defmodule Flowex.PipelineBuilder do
  import Supervisor.Spec

  def start(pipeline_module, opts) do
    {:ok, sup_pid} = Flowex.Supervisor.start_link(pipeline_module)
    do_start(sup_pid, pipeline_module, opts)
  end

  def supervised_start(pipeline_module, pid, opts) do
    sup_spec = supervisor(Flowex.Supervisor, pipeline_module, [id: "Flowex.Supervisor_#{inspect make_ref()}", restart: :permanent])
    {:ok, sup_pid} = Supervisor.start_child(pid, sup_spec)
    do_start(sup_pid, pipeline_module, opts)
  end

  def stop(sup_pid) do
    Supervisor.which_children(sup_pid)
    |> Enum.each(fn({id, _pid, :worker, [_]}) ->
      Supervisor.terminate_child(sup_pid, id)
    end)
    Supervisor.stop(sup_pid)
  end

  defp do_start(sup_pid, pipeline_module, opts) do
    [{producer_name, _in_producer, :worker, [Flowex.Producer]}] = Supervisor.which_children(sup_pid)

    last_names = (pipeline_module.pipes() ++ [pipeline_module.error_pipe])
    |> Enum.reduce([producer_name], fn({atom, count, type}, prev_pids) ->
      (1..count)
      |> Enum.map(fn(_i) ->
        case Atom.to_char_list(atom) do
          ~c"Elixir." ++ _ -> init_module_pipe(sup_pid, {type, atom, opts}, prev_pids)
          _ ->  init_function_pipe(sup_pid, {type, pipeline_module, atom, opts}, prev_pids)
        end
      end)
    end)

    consumer_name = String.to_atom("Flowex.Consumer_#{inspect pipeline_module}_#{inspect make_ref()}")
    worker_spec = worker(Flowex.Consumer, [last_names, [name: consumer_name]], [id: consumer_name])
    {:ok, _out_consumer_pid} = Supervisor.start_child(sup_pid, worker_spec)

    %Flowex.Pipeline{module: pipeline_module, in_name: producer_name, out_name: consumer_name, sup_pid: sup_pid}
  end

  defp init_function_pipe(sup_pid, {type, pipeline_module, function, opts}, prev_pids) do
    name = String.to_atom("Flowex_#{pipeline_module}.#{function}_#{inspect make_ref()}")
    worker_spec = worker(Flowex.Stage,
                         [{type, pipeline_module, function, opts, prev_pids}, [name: name]],
                         [id: name])
    {:ok, _pid} = Supervisor.start_child(sup_pid, worker_spec)
    name
  end

  defp init_module_pipe(sup_pid, {type, module, opts}, prev_pids) do
    opts = module.init(opts)
    name = String.to_atom("Flowex_#{module}.call_#{inspect make_ref()}")
    worker_spec = worker(Flowex.Stage,
                         [{type, module, :call, opts, prev_pids}, [name: name]],
                         [id: name])
    {:ok, _pid} = Supervisor.start_child(sup_pid, worker_spec)
    name
  end
end
