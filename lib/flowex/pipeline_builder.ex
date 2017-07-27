defmodule Flowex.PipelineBuilder do
  @moduledoc "Defines functions to start and to stop a pipeline"

  import Supervisor.Spec

  def start(pipeline_module, opts) do
    {producer_name, consumer_name, all_specs} = build_children(pipeline_module, opts)

    sup_name = supervisor_name(pipeline_module)
    {:ok, sup_pid} = Flowex.Supervisor.start_link(all_specs, sup_name)

    pipeline_struct(pipeline_module, producer_name, consumer_name, sup_pid)
  end

  def supervised_start(pipeline_module, pid, opts) do
    {producer_name, consumer_name, all_specs} = build_children(pipeline_module, opts)

    sup_name = supervisor_name(pipeline_module)
    sup_spec = supervisor(Flowex.Supervisor, [all_specs, sup_name], [id: sup_name, restart: :permanent])
    {:ok, sup_pid} = Supervisor.start_child(pid, sup_spec)
    pipeline_struct(pipeline_module, producer_name, consumer_name, sup_pid)
  end

  def stop(sup_pid) do
    Enum.each(Supervisor.which_children(sup_pid), fn({id, _pid, :worker, [_]}) ->
      Supervisor.terminate_child(sup_pid, id)
    end)
    Supervisor.stop(sup_pid)
  end

  defp build_children(pipeline_module, opts) do
    producer_name = producer_name(pipeline_module)
    producer_spec = worker(Flowex.Producer, [nil, [name: producer_name]], id: producer_name)

    {wss, last_names} = init_pipes({producer_spec, producer_name}, {pipeline_module, opts})

    consumer_name = consumer_name(pipeline_module)
    consumer_worker_spec = worker(Flowex.Consumer, [last_names, [name: consumer_name]], [id: consumer_name])

    {producer_name, consumer_name, wss ++ [consumer_worker_spec]}
  end

  defp supervisor_name(pipeline_module) do
    String.to_atom("Flowex.Supervisor_#{inspect pipeline_module}_#{inspect make_ref()}")
  end

  defp producer_name(pipeline_module) do
   String.to_atom("Flowex.Producer_#{inspect pipeline_module}_#{inspect make_ref()}")
  end

  defp consumer_name(pipeline_module) do
    String.to_atom("Flowex.Consumer_#{inspect pipeline_module}_#{inspect make_ref()}")
  end

  defp pipeline_struct(pipeline_module, producer_name, consumer_name, sup_pid) do
    %Flowex.Pipeline{module: pipeline_module, in_name: producer_name,
                     out_name: consumer_name, sup_pid: sup_pid}
  end

  defp init_pipes({producer_spec, producer_name}, {pipeline_module, opts}) do
    (pipeline_module.pipes() ++ [pipeline_module.error_pipe])
    |> Enum.reduce({[producer_spec], [producer_name]}, fn({atom, count, pipe_opts, type}, {wss, prev_names}) ->
      opts = Map.merge(Enum.into(opts, %{}), Enum.into(pipe_opts, %{}))
      list = Enum.map((1..count), fn(_i) ->
        init_pipe({pipeline_module, opts}, {atom, type}, prev_names)
      end)
      {new_wss, names} = Enum.unzip(list)
      {wss ++ new_wss , names}
    end)
  end

  def init_pipe({pipeline_module, opts}, {atom, type}, prev_names) do
    case Atom.to_char_list(atom) do
      ~c"Elixir." ++ _ -> init_module_pipe({type, atom, opts}, prev_names)
      _ -> init_function_pipe({type, pipeline_module, atom, opts}, prev_names)
    end
  end

  defp init_function_pipe({type, pipeline_module, function, opts}, prev_names) do
    name = String.to_atom("Flowex_#{pipeline_module}.#{function}_#{inspect make_ref()}")
    worker_spec = worker(Flowex.Stage,
                         [{type, pipeline_module, function, opts, prev_names}, [name: name]],
                         [id: name])
    {worker_spec, name}
  end

  defp init_module_pipe({type, module, opts}, prev_names) do
    opts = module.init(opts)
    name = String.to_atom("Flowex_#{module}.call_#{inspect make_ref()}")
    worker_spec = worker(Flowex.Stage,
                         [{type, module, :call, opts, prev_names}, [name: name]],
                         [id: name])
    {worker_spec, name}
  end
end
