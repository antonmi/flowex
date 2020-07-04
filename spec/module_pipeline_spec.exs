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
      expect(pipeline().sup_name) |> to(be_atom())
    end
  end

  describe ".stop" do
    let! :pipeline, do: ModulePipeline.start(opts())
    let! :sup_pid, do: Process.whereis(pipeline().sup_name)

    it "stops supervisor" do
      assert Process.alive?(sup_pid())
      ModulePipeline.stop(pipeline())
      refute Process.alive?(sup_pid())
    end
  end

  describe ".call" do
    let :pipeline, do: ModulePipeline.start(opts())
    let :output, do: ModulePipeline.call(pipeline(), %ModulePipeline{number: 2})

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
          ModulePipeline.call(pipeline(), %ModulePipeline{number: 2}).number
        end)
        {:ok, numbers: numbers}
      end

      it "returns the same results" do
        expected = Enum.map(attempts(), fn(_) -> 3 end)
        assert shared.numbers == expected
      end
    end
  end

  context "when error inside stage" do
    let :pipeline, do: ModulePipeline.start(opts())
    let :output, do: ModulePipeline.call(pipeline(), %ModulePipeline{number: :not_a_number})

    it "return struct with error" do
      expect(output().__struct__) |> to(eq ModulePipeline)
      expect(output().number.__struct__) |> to(eq Flowex.PipeError)
    end

    context "checks error" do
      let :error, do: output().number

      it "has message" do
        expect(error().message) |> to(eq "bad argument in arithmetic expression")
      end

      it "has pipe info" do
        expect(error().pipe) |> to(eq {AddOne, :call, %{a: :add_one, b: :b, c: :c}})
      end

      it "has struct info" do
        expect(error().struct[:number]) |> to(eq :not_a_number)
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
        output1: ModulePipeline.call(shared.pipeline1, %ModulePipeline{number: 2}),
        output2: ModulePipeline.call(shared.pipeline2, %ModulePipeline{number: 2}),
        output3: FunPipeline.call(shared.pipeline3, %FunPipeline{number: 2}),
        output4: FunPipeline.call(shared.pipeline3, %FunPipeline{number: 2})
      }
    end

    it "returns 3" do
      expect(shared.output1.number) |> to(eq 3)
      expect(shared.output2.number) |> to(eq 3)
      expect(shared.output3.number) |> to(eq 3)
      expect(shared.output4.number) |> to(eq 3)
    end
  end
end
