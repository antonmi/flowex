defmodule Flowex.Producer do
  use Experimental.GenStage

  def start_link(state) do
    Experimental.GenStage.start_link(__MODULE__, state)
  end

  def init(_), do: {:producer, [], demand: :accumulate}

  def handle_demand(_demand, [ip | ips]) do
    {:noreply, [ip], ips}
  end

  def handle_demand(_demand, []) do
    receive do
      %Flowex.IP{} = ip -> {:noreply, [ip], []}
      _ -> raise "Must be an Flowex.IP"
    end
  end

  def handle_info(ip, ips) do
    {:noreply, [], [ip | ips]}
  end
end
