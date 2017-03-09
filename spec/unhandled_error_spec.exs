defmodule UnhandledErrorSpec do
  use ESpec, async: true

  defmodule Pipeline do
    use Flowex.Pipeline

    defstruct data: nil
    pipe :one, 2
    pipe :fun, 2
    pipe :second, 2
    pipe :at_the_end, 2
    error_pipe :if_error, 2

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
    let :pipeline, do: Pipeline.start

    let :func do
      fn ->
        Pipeline.call(UnhandledErrorSpec.pipeline() ,%Pipeline{data: :fail})
      end
    end

    it "raises a Flowex.PipelineError but still works" do
      expect(func()).to raise_exception(Flowex.PipelineError)
      Process.sleep(100)
      expect(Pipeline.call(pipeline() ,%Pipeline{data: :ok})).to eq(%Pipeline{data: :ok})
    end
  end
end
