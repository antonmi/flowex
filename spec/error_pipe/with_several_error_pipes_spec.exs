defmodule WithSeveralErrorPipesSpec do
  use ESpec, async: true

  defmodule Pipeline do
    use Flowex.Pipeline

    defstruct data: nil, error: nil

    pipe :one
    pipe :two
    pipe :three
    error_pipe :if_error1
    error_pipe :if_error2
    error_pipe :if_error3

    def one(_struct, _opts), do: raise "error"
    def two(struct, _opts), do: struct
    def three(struct, _opts), do: struct

    def if_error1(_error, _struct, _opts), do: raise "ignored"
    def if_error2(_error, _struct, _opts), do: raise "ignored"
    def if_error3(error, struct, _opts), do: %{struct | error: error}
  end

  let :result do
    pipeline = Pipeline.start
    Pipeline.call(pipeline, %Pipeline{data: nil})
  end

  it "return struct with error" do
    expect(result().__struct__) |> to(eq Pipeline)
    expect(result().error.__struct__) |> to(eq Flowex.PipeError)
  end
end
