defmodule UnhandledErrorSpec do
  use ESpec, async: true

  defmodule Pipeline do
    use Flowex.Pipeline

    defstruct data: nil
    pipe :one, count: 2
    pipe :fun, count: 2
    pipe :second, count: 2
    pipe :at_the_end, count: 2
    error_pipe :if_error, count: 2

    def one(struct, _opts), do: struct

    def fun(struct, _opts) do
      if struct.data == :fail do
        Process.exit(self(), :kill)
      else
        struct
      end
    end

    def second(struct, _opts), do: struct
    def at_the_end(struct, _opts), do: struct

    def if_error(error, _struct, _opts) do
      raise error
    end
  end

  context "with crash" do
    let! :pipeline, do: Pipeline.start

    let :func do
      fn ->
        Pipeline.call(UnhandledErrorSpec.pipeline() ,%Pipeline{data: :fail})
      end
    end

    it "raises a Flowex.PipelineError but still works" do
      expect(func()).to raise_exception(Flowex.PipelineError)
      Process.sleep(100)
      expect(Pipeline.call(pipeline() ,%Pipeline{data: :ok})).to eq(%Pipeline{data: :ok})
      #one more time
      expect(func()).to raise_exception(Flowex.PipelineError)
      Process.sleep(100)
      expect(Pipeline.call(pipeline() ,%Pipeline{data: :ok})).to eq(%Pipeline{data: :ok})
    end
  end

  context "supervisor crash" do
    before do
      {:ok, supervisor_pid} = Supervisor.start_link([], strategy: :one_for_one)
      pipeline = Pipeline.supervised_start(supervisor_pid)
      {:shared, pipeline: pipeline}
    end

    let! :old_pid, do: Process.whereis(shared.pipeline.sup_name)

    before do
      pid = Process.whereis(shared.pipeline.sup_name)
      Process.exit(pid, :kill)
      Process.sleep(200)
    end

    it "kills supervisor" do
      expect(Process.alive?(old_pid)).to be false
    end

    it "restarts successfully" do
      expect(Pipeline.call(shared.pipeline ,%Pipeline{data: :ok})).to eq(%Pipeline{data: :ok})
    end
  end
end
