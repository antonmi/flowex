defmodule Flowex.Sync.GenServer do
  use GenServer

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def handle_call(ip, _from, {pipeline_module, opts}) do
    result = do_call(ip, {pipeline_module, opts})
    {:reply, result, {pipeline_module, opts}}
  end

  def handle_cast(ip, {pipeline_module, opts}) do
    do_call(ip, {pipeline_module, opts})
    {:noreply, {pipeline_module, opts}}
  end

  defp do_call(ip, {pipeline_module, opts}) do
    (pipeline_module.pipes() ++ [pipeline_module.error_pipe])
    |> Enum.reduce(ip, fn(pipe, ip) ->
      process(pipe, ip, pipeline_module, opts)
    end)
  end

  defp try_apply(ip, {module, function, pipe_opts}) do
      result = apply(module, function, [ip.struct, pipe_opts])
      %{ip | struct: Map.merge(ip.struct, Map.delete(result, :__struct__))}
  rescue
      error ->
        error_struct = %Flowex.PipeError{message: Exception.message(error),
                                        pipe: {module, function, pipe_opts},
                                        struct: ip.struct}
        %{ip | error: error_struct}
  end

  defp process(pipe, ip, pipeline_module, opts) do
    {atom, _count, pipe_opts, type} = pipe
    if ip.error do
      do_preocess_error(ip, pipeline_module, atom, {opts, pipe_opts}, type)
    else
      do_process(ip, pipeline_module, atom, {opts, pipe_opts})
    end
  end

  defp do_process(ip, pipeline_module, atom, {opts, pipe_opts}) do
    pipe_opts = Map.merge(Enum.into(opts, %{}), Enum.into(pipe_opts, %{}))
    case Atom.to_char_list(atom) do
      ~c"Elixir." ++ _ ->
        pipe_opts = atom.init(pipe_opts)
        try_apply(ip, {atom, :call, pipe_opts})
      _ -> try_apply(ip, {pipeline_module, atom, pipe_opts})
    end
  end

  defp do_preocess_error(ip, pipeline_module, atom, {opts, pipe_opts}, :error_pipe) do
    pipe_opts = Map.merge(Enum.into(opts, %{}), Enum.into(pipe_opts, %{}))
    result = case Atom.to_char_list(atom) do
      ~c"Elixir." ++ _ ->
        pipe_opts = atom.init(pipe_opts)
        apply(atom, :call, [ip.error, ip.struct, pipe_opts])
      _ -> apply(pipeline_module, atom, [ip.error, ip.struct, pipe_opts])
    end
    %{ip | struct: Map.merge(ip.struct, result)}
  end

  defp do_preocess_error(ip, _pipeline_module, _atom, _opts, :pipe), do: ip
end
