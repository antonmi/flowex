defmodule InterfacePipelineSpec do
  use ESpec

  let :pipeline, do: described_module().start()
  let :result, do: described_module().call(pipeline(), %InterfacePipeline{x: 1, y: 2, ok: :ok})

  it "returns result" do
    expected = %InterfacePipeline{a: 3, b: 2, foo: "Hello", ok: :ok, p: "Hello - 4", q: 2, x: 4, y: 2, z: :z}
    result() |> should(eq expected)
  end

  describe "DataAvailable" do
    let :pipeline, do: DataAvailable.start()
    let :result, do: DataAvailable.call(pipeline(), %DataAvailable{top: 100, c1: 1})

    it "returns result" do
      expected = %DataAvailable{c1: 1, foo: :set_foo, top: 105}
      result() |> should(eq expected)
    end
  end
end
