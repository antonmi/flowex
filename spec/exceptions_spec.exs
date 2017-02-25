defmodule ExceptionsSpec do
  use ESpec, async: true

  defmodule Pipeline do
    use Flowex.Pipeline

    defstruct data: nil
    pipe :fun

    def fun(struct, _opts) do
      if struct.data == :fail do
        raise "Fail"
      else
        struct
      end
    end
  end

  let! :pipeline, do: Pipeline.start

  context "with crash" do
    def run_pipeline(struct) do
      Pipeline.call(ExceptionsSpec.pipeline(), struct)
    end

    let :func do
      fn -> run_pipeline(%Pipeline{data: :fail}) end
    end

    it "raises a Flowex.PipelineError but still works" do
      expect(func()).to raise_exception(Flowex.PipelineError)
      Process.sleep(100)
      expect(run_pipeline(%Pipeline{data: :ok})).to eq(%Pipeline{data: :ok})
    end
  end
end
