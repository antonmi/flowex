defmodule Flowex.Stage do
  use Experimental.GenStage

  def start_link(state, _opts \\ []) do
    Experimental.GenStage.start_link(__MODULE__, state)
  end

  def init({module, function, opts, subscribe_to}) do
    subscribe_to = Enum.map(subscribe_to, &({&1,  max_demand: 1}))
    {:producer_consumer, {module, function, opts}, subscribe_to: subscribe_to}
  end

  def handle_events([ip], _from, {module, function, opts}) do
    new_ip = %{ip | struct: apply(module, function, [ip.struct, opts])}
    {:noreply, [new_ip], {module, function, opts}}
  end
end
