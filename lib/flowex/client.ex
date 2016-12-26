defmodule Flowex.Client do
  use GenServer

  def start(pipeline) do
    GenServer.start_link(__MODULE__, pipeline)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def init(pipeline) do
    {:ok, pipeline}
  end

  def run(pid, struct) do
    GenServer.call(pid, {:run, struct}, :infinity)
  end

  def run!(pipeline, struct) do
    {:ok, pid} = GenServer.start_link(__MODULE__, pipeline)
    result = GenServer.call(pid, {:run, struct}, :infinity)
    GenServer.stop(pid)
    result
  end

  def handle_call({:run, struct}, _pid, pipeline) do
    struct = pipeline.module.run(pipeline, struct)
    {:reply, struct, pipeline}
  end
end
