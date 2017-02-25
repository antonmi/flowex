defmodule Flowex.Supervisor do
  use Supervisor

  def start_link(pipeline_module) do
    Supervisor.start_link(__MODULE__, pipeline_module)
  end

  def init(pipeline_module) do
    name = String.to_atom("Flowex.Producer_#{inspect pipeline_module}_#{inspect make_ref()}")
    children = [
      worker(Flowex.Producer, [nil, [name: name]], id: name)
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
