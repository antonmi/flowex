defmodule IntrospectionSpec do
  use ESpec, async: true

  describe InitOptsFunPipeline do
    describe ".pipes" do
      it "returns pipe list" do
        InitOptsFunPipeline.pipes()
        |> should(eq([{:component, 2, %{from_opts: 3}, :pipe}]))
      end
    end

    describe ".pipe_info" do
      it "returns pipe info" do
        pipe_info = InitOptsFunPipeline.pipe_info(:component)
        expect(pipe_info[:name]).to eq(:component)
        expect(pipe_info[:count]).to eq(2)
        expect(pipe_info[:opts]).to eq(%{from_opts: 3})
        expect(pipe_info[:type]).to eq(:pipe)
      end
    end
  end

  describe InitOptsModulePipeline do
    describe ".pipes" do
      it "returns pipe list" do
        InitOptsModulePipeline.pipes()
        |> should(eq([{OptComponent, 2, %{from_opts: 3}, :pipe}]))
      end
    end

    describe ".pipe_info" do
      it "returns pipe info" do
        pipe_info = InitOptsModulePipeline.pipe_info(OptComponent)
        expect(pipe_info[:name]).to eq(OptComponent)
        expect(pipe_info[:count]).to eq(2)
        expect(pipe_info[:opts]).to eq(%{from_opts: 3})
        expect(pipe_info[:type]).to eq(:pipe)
      end
    end
  end
end
