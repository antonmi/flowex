defmodule Flowex.Component do
  use Experimental.GenStage

  def init({module, function, subscribe_to}) do
    subscribe_to = Enum.map(subscribe_to, &({&1,  max_demand: 1}))
    {:producer_consumer, {module, function}, subscribe_to: subscribe_to}
  end

  def handle_events([ip], _from, {module, function}) do
    new_ip = %{ip | struct: apply(module, function, [ip.struct])}
    {:noreply, [new_ip], {module, function}}
  end
end
