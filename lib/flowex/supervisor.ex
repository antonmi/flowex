defmodule Flowex.Supervisor do
  use Supervisor

  def start_link(pipeline_module) do
    Supervisor.start_link(__MODULE__, pipeline_module)
  end

  def init(_pipeline_module) do
    name = String.to_atom("Flowex.Producer_#{inspect make_ref()}")
    children = [
      worker(Flowex.Producer, [nil, [name: name]], id: name)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
