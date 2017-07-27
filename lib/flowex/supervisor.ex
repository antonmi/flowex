defmodule Flowex.Supervisor do
  @moduledoc "Pipeline supevisor"

  use Supervisor

  def start_link(children, name) do
    Elixir.Supervisor.start_link(__MODULE__, children, name: name)
  end

  def init(children) do
    supervise(children, strategy: :rest_for_one)
  end
end
