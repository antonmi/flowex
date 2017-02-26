defmodule Flowex.Stage do
  use GenStage

  def start_link(state, opts \\ []) do
    GenStage.start_link(__MODULE__, state, opts)
  end

  def init({type, module, function, opts, subscribe_to}) do
    subscribe_to = Enum.map(subscribe_to, &({&1,  max_demand: 1}))
    {:producer_consumer, {type, module, function, opts}, subscribe_to: subscribe_to}
  end

  def handle_events([ip], _from, {:pipe, module, function, opts}) do
    if ip.error do
      {:noreply, [ip], {:pipe, module, function, opts}}
    else
      new_ip = try_apply(ip, {module, function, opts})
      {:noreply, [new_ip], {:pipe, module, function, opts}}
    end
  end

  def handle_events([ip], _from, {:error_pipe, module, function, opts}) do
    if ip.error do
      new_ip = %{ip | struct: apply(module, function, [ip.error, ip.struct, opts])}
      {:noreply, [new_ip], {:error_pipe, module, function, opts}}
    else
      {:noreply, [ip], {:error_pipe, module, function, opts}}
    end
  end

  defp try_apply(ip, {module, function, opts}) do
    try do
      %{ip | struct: apply(module, function, [ip.struct, opts])}
    rescue
      error ->
        %{ip | error: %Flowex.PipeError{message: error.message, pipe: {module, function, opts}, struct: ip.struct}}
    end
  end
end
