defmodule WithErrorPipeSpec do
  use ESpec, async: true

  defmodule Pipeline do
    use Flowex.Pipeline

    defstruct data: nil, error: nil
    pipe :one
    pipe :two
    pipe :three
    error_pipe :if_error

    def one(_struct, _opts), do: raise(ArithmeticError, "error")
    def two(struct, _opts), do: struct
    def three(struct, _opts), do: struct

    def if_error(error, struct, _opts) do
      %{struct | error: error}
    end
  end

  let :result do
    pipeline = Pipeline.start
    Pipeline.call(pipeline, %Pipeline{data: nil})
  end

  it "return struct with error" do
    expect(result().__struct__).to eq(Pipeline)
    expect(result().error.__struct__).to eq(Flowex.PipeError)
    expect(result().error.error).to eq(%ArithmeticError{message: "error"})
  end

  context "checks error" do
    let :error, do: result().error

    it "has message" do
      expect(error().message).to eq("error")
    end

    it "has pipe info" do
      expect(error().pipe).to eq({WithErrorPipeSpec.Pipeline, :one, %{}})
    end

    it "has struct info" do
      expect(error().struct).to eq(%{data: nil, error: nil})
    end
  end
end
