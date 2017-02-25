defmodule WithoutErrorPipeSpec do
  use ESpec, async: true

  defmodule Pipeline do
    use Flowex.Pipeline

    defstruct data: nil
    pipe :one
    pipe :two
    pipe :three

    def one(_struct, _opts), do: raise "error"
    def two(struct, _opts), do: struct
    def three(struct, _opts), do: struct
  end

  describe WithoutErrorPipe do
    def run_pipeline do
      pipeline = Pipeline.start
      Pipeline.call(pipeline, %Pipeline{data: nil})
    end

    let :func do
      fn -> run_pipeline() end
    end

    it "raises exception" do
      expect(func()).to raise_exception(Flowex.PipelineError)
    end
  end
end
