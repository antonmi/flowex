defmodule Flowex.Stage do
  use GenStage

  def start_link(state, opts \\ []) do
    GenStage.start_link(__MODULE__, state, opts)
  end

  def init({type, module, function, opts, subscribe_to}) do
    subscribe_to = Enum.map(subscribe_to, &({&1,  max_demand: 1}))
    {:producer_consumer, {type, module, function, opts}, subscribe_to: subscribe_to}
  end

  def handle_events([ip], _from, {type, module, function, opts}) do
    if ip.error do
      if type == :error_pipe do
        new_ip = %{ip | struct: apply(module, function, [ip.error, ip.struct, opts])}
        {:noreply, [new_ip], {type, module, function, opts}}
      else
        {:noreply, [ip], {type, module, function, opts}}
      end
    else
      new_ip = try do
        if type == :pipe do
          %{ip | struct: apply(module, function, [ip.struct, opts])}
        else
          ip
        end
      rescue
        error ->
          %{ip | error: %Flowex.StageError{message: error.message, pipe: {module, function, opts}, struct: ip.struct}}
      end
      {:noreply, [new_ip], {type, module, function, opts}}
    end
  end
end
