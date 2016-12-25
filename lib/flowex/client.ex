defmodule Flowex.Client do
  use GenServer

  def start(chain) do
    GenServer.start_link(__MODULE__, chain)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def init(chain) do
    {:ok, chain}
  end

  def run(pid, data) do
    GenServer.call(pid, {:run, data}, :infinity)
  end

  def run!(chain, data) do
    {:ok, pid} = GenServer.start_link(__MODULE__, chain)
    result = GenServer.call(pid, {:run, data}, :infinity)
    GenServer.stop(pid)
    result
  end

  def handle_call({:run, data}, _pid, chain) do
    data = chain.module.run(chain, data)
    {:reply, data, chain}
  end
end
