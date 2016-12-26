defmodule FunPipelineSpec do
  use ESpec, async: true

  describe ".start" do
    let :pipeline, do: FunPipeline.start

    describe "pipeline struct" do
      it do: expect(pipeline()) |> to(be_struct Flowex.Pipeline)
      it do: expect(pipeline().module) |> to(eq FunPipeline)
      it do: expect(pipeline().in_pid) |> to(be_pid())
      it do: expect(pipeline().out_pid) |> to(be_pid())

      xit do: expect(pipeline().sup_pid) |> to(be_pid())
    end
  end

  describe ".stop" do
    xit do: "not implemented yet"
  end

  describe ".run" do
    let :opts, do: %{a: :a, b: :b, c: :c}
    let :pipeline, do: FunPipeline.start(opts())
    let :output, do: FunPipeline.run(pipeline(), %FunPipeline{})

    it do: assert output().number == 4

    it "sets a, b, c" do
      assert output().a == :a
      assert output().b == :b
      assert output().c == :c
    end

    context "when running several times" do
      let :attempts, do: (1..3)

      before do
        numbers = Enum.map(attempts(), fn(_) -> FunPipeline.run(pipeline(), %FunPipeline{}).number end)
        {:ok, numbers: numbers}
      end

      it "returns the same results" do
        expected = Enum.map(attempts(), fn(_) -> 4 end)
        assert shared.numbers == expected
      end
    end
  end
end
