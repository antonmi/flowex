defmodule InitializationSpec do
  use ESpec, async: true

  describe "function pipeline" do
    let :pipeline, do: InitOptsFunPipeline.start(%{from_start: 1})
    let :result, do: InitOptsFunPipeline.call(pipeline(), %InitOptsFunPipeline{})

    it "returns values from different init functions" do
      expect(result())
      |> to(eq %InitOptsFunPipeline{from_start: 1, from_init: 2, from_opts: 3})
    end
  end

  describe "module pipeline" do
    let :pipeline, do: InitOptsModulePipeline.start(%{from_start: 1})
    let :result, do: InitOptsModulePipeline.call(pipeline(), %InitOptsModulePipeline{})

    it "returns values from different init functions" do
      expect(result())
      |> to(eq %InitOptsModulePipeline{from_start: 1, from_init: 2, from_opts: 3, component_init: 4})
    end
  end
end
