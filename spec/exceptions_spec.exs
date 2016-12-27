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

  let :pipeline, do: Pipeline.start
  let :out, do: Pipeline.run(pipeline(), %Pipeline{data: 2})

  context "with crash" do
    before do
      # Pipeline.run(pipeline(), %Pipeline{data: :fail})
    end

    it "adfas" do
      # IO.inspect(out)
    end
  end


end
