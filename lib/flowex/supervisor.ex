defmodule Flowex.Supervisor do
  use Supervisor

  def start_link(pipeline_module) do
    Supervisor.start_link(__MODULE__, pipeline_module)
  end

  def init(pipeline_module) do
    children = [
      worker(Flowex.Producer, [nil], id: {Flowex.Producer, nil, make_ref()})
    ]

    supervise(children, strategy: :one_for_one)
  end
end
