defmodule Flowex.Producer do
  use Experimental.GenStage

  def start_link(nil, opts \\ []) do
    Experimental.GenStage.start_link(__MODULE__, nil, opts)
  end

  def init(_), do: {:producer, []}

  def handle_demand(_demand, [ip | ips]) do
    {:noreply, [ip], ips}
  end

  def handle_demand(_demand, []) do
    {:noreply, [], []}
  end

  def handle_cast(%Flowex.IP{} = ip, ips) do
    {:noreply, [ip], ips}
  end
end
