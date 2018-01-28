defmodule Flowex.Client do
  @moduledoc "Absctraction to call the pipeline"

  use GenServer

  def start(pipeline, opts \\ []) do
    GenServer.start_link(__MODULE__, pipeline, opts)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def init(pipeline) do
    {:ok, pipeline}
  end

  def call(pid, struct) do
    GenServer.call(pid, {:call, struct}, :infinity)
  end

  def cast(pid, struct) do
    GenServer.cast(pid, {:cast, struct})
  end

  def call!(pipeline, struct) do
    {:ok, pid} = GenServer.start_link(__MODULE__, pipeline)
    result = GenServer.call(pid, {:call, struct}, :infinity)
    GenServer.stop(pid)
    result
  end

  def handle_call({:call, struct}, _pid, pipeline) do
    struct = pipeline.module.call(pipeline, struct)
    {:reply, struct, pipeline}
  end

  def handle_cast({:cast, struct}, pipeline) do
    pipeline.module.cast(pipeline, struct)
    {:noreply, pipeline}
  end
end
