defmodule ModulePipelineSpec do
  use ESpec, async: true

  let :opts, do: %{a: :a, b: :b, c: :c}

  describe ".start" do
    let :pipeline, do: ModulePipeline.start(opts())

    describe "pipeline struct" do
      it do: expect(pipeline()) |> to(be_struct Flowex.Pipeline)
      it do: expect(pipeline().module) |> to(eq ModulePipeline)
      it do: expect(pipeline().in_pid) |> to(be_pid())
      it do: expect(pipeline().out_pid) |> to(be_pid())

      xit do: expect(pipeline().sup_pid) |> to(be_pid())
    end
  end

  describe ".stop" do
    xit do: "not implemented yet"
  end

  describe ".run" do
    let :pipeline, do: ModulePipeline.start(opts())
    let :output, do: ModulePipeline.run(pipeline(), %ModulePipeline{number: 2})

    it do: assert output().number == 3

    it "sets a, b, c" do
      assert output().a == :add_one
      assert output().b == :mult_by_two
      assert output().c == :minus_three
    end

    context "when running several times" do
      let :attempts, do: (1..3)

      before do
        numbers = Enum.map(attempts(), fn(_) ->
          ModulePipeline.run(pipeline(), %ModulePipeline{number: 2}).number
        end)
        {:ok, numbers: numbers}
      end

      it "returns the same results" do
        expected = Enum.map(attempts(), fn(_) -> 3 end)
        assert shared.numbers == expected
      end
    end
  end
end
