defmodule ModulePipelineSpec do
  use ESpec, async: true

  let :opts, do: %{a: :a, b: :b, c: :c}

  describe ".start" do
    let :pipeline, do: ModulePipeline.start(opts())

    it "checks pipeline struct" do
      expect(pipeline()) |> to(be_struct Flowex.Pipeline)
      expect(pipeline().module) |> to(eq ModulePipeline)
      expect(pipeline().in_name) |> to(be_atom())
      expect(pipeline().out_name) |> to(be_atom())
      expect(pipeline().sup_pid) |> to(be_pid())
    end
  end

  describe ".stop" do
    let! :pipeline, do: ModulePipeline.start(opts())
    let! :sup_pid, do: pipeline().sup_pid

    it "stops supervisor" do
      assert Process.alive?(sup_pid())
      ModulePipeline.stop(pipeline())
      refute Process.alive?(sup_pid())
    end
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

  describe "several pipelines" do
    before do
      {:shared,
        pipeline1: ModulePipeline.start(opts()),
        pipeline2: ModulePipeline.start(opts()),
        pipeline3: FunPipeline.start(opts()),
        pipeline4: FunPipeline.start(opts())
      }
    end

    before do
      {:shared,
        output1: ModulePipeline.run(shared.pipeline1, %ModulePipeline{number: 2}),
        output2: ModulePipeline.run(shared.pipeline2, %ModulePipeline{number: 2}),
        output3: FunPipeline.run(shared.pipeline3, %FunPipeline{number: 2}),
        output4: FunPipeline.run(shared.pipeline3, %FunPipeline{number: 2})
      }
    end

    it "returns 3" do
      expect(shared.output1.number).to eq(3)
      expect(shared.output2.number).to eq(3)
      expect(shared.output3.number).to eq(3)
      expect(shared.output4.number).to eq(3)
    end
  end
end
