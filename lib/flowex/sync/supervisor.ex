defmodule Flowex.Sync.Supervisor do
  @moduledoc "Sync pipeline supevisor"

  use Supervisor

  def start_link(pipeline_module, opts) do
    Supervisor.start_link(__MODULE__, [pipeline_module, opts])
  end

  def init([pipeline_module, opts]) do
    name = String.to_atom("Flowex.Sync_#{inspect pipeline_module}_#{inspect make_ref()}")
    children = [
      worker(Flowex.Sync.GenServer, [{pipeline_module, opts}, [name: name]], id: name)
    ]
    supervise(children, strategy: :one_for_one)
  end
end
