defmodule ExceptionsSpec do
  use ESpec

  defmodule Pipeline do
    use Flowex.Pipeline

    defstruct data: nil
    pipe :fun

    def fun(struct, opts) do
      if struct.data == :fail do
        raise "Fail"
      else
        struct
      end
    end
  end

  let! :pipeline, do: Pipeline.start

  context "with crash" do
    before do
      Process.sleep(1000)
      IO.inspect("Starting crash")
      # Pipeline.run(pipeline(), %Pipeline{data: :fail})
      Process.sleep(1000)
      IO.inspect("End of crash")
    end

    it "adfas" do
      out = Pipeline.run(pipeline(), %Pipeline{data: 2})
      IO.inspect(out)
    end
  end


end
