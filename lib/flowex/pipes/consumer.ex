defmodule Flowex.Consumer do
  use GenStage

  def start_link(subscribe_to, opts \\ []) do
    GenStage.start_link(__MODULE__, subscribe_to, opts)
  end

  def init(subscribe_to \\ []) do
    subscribe_to = Enum.map(subscribe_to, &({&1,  max_demand: 1}))
    {:consumer, nil, subscribe_to: subscribe_to}
  end

  def handle_events([ip], _from, nil) do
    send(ip.requester, ip)
    {:noreply, [], nil}
  end

  def handle_cast({in_name, ip}, nil) do
    GenStage.cast(in_name, ip)
    {:noreply, [], nil}
  end
end
