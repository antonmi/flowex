defmodule ModulePipelineSyncSpec do
  use ESpec, async: true

  let :opts, do: %{a: :a, b: :b, c: :c}

  describe ".start" do
    let :pipeline, do: ModulePipelineSync.start(opts())

    it "checks pipeline struct" do
      expect(pipeline()) |> to(be_struct Flowex.Pipeline)
      expect(pipeline().module) |> to(eq ModulePipelineSync)
      expect(pipeline().in_name) |> to(be_atom())
      expect(pipeline().out_name) |> to(be_atom())
      expect(pipeline().sup_pid) |> to(be_pid())
    end
  end

  describe ".stop" do
    let! :pipeline, do: ModulePipelineSync.start(opts())
    let! :sup_pid, do: pipeline().sup_pid

    it "stops supervisor" do
      assert Process.alive?(sup_pid())
      ModulePipelineSync.stop(pipeline())
      refute Process.alive?(sup_pid())
    end
  end

  describe ".call" do
    let :pipeline, do: ModulePipelineSync.start(opts())
    let :output, do: ModulePipelineSync.call(pipeline(), %ModulePipelineSync{number: 2})

    it do: assert output().number == 3

    it "sets a, b, c" do
      assert output().a == :add_one
      assert output().b == :mult_by_two
      assert output().c == :minus_three
    end
  end

  context "when error inside stage" do
    let :pipeline, do: ModulePipelineSync.start(opts())
    let(:output) do
      ModulePipelineSync.call(pipeline(), %ModulePipelineSync{number: :not_a_number})
    end

    it "return struct with error" do
      expect(output().__struct__).to eq(ModulePipelineSync)
      expect(output().number.__struct__).to eq(Flowex.PipeError)
    end

    context "checks error" do
      let :error, do: output().number

      it "has message" do
        expect(error().message).to eq("bad argument in arithmetic expression")
      end

      it "has pipe info" do
        expect(error().pipe).to eq({AddOne, :call, %{a: :add_one, b: :b, c: :c, o1: 1}})
      end

      it "has struct info" do
        expect(error().struct[:number]).to eq(:not_a_number)
      end
    end
  end

  describe "several pipelines" do
    before do
      {:shared,
        pipeline1: ModulePipelineSync.start(opts()),
        pipeline2: ModulePipelineSync.start(opts()),
        pipeline3: FunPipelineSync.start(opts()),
        pipeline4: FunPipelineSync.start(opts())
      }
    end

    before do
      {:shared,
        output1: ModulePipelineSync.call(shared.pipeline1, %ModulePipelineSync{number: 2}),
        output2: ModulePipelineSync.call(shared.pipeline2, %ModulePipelineSync{number: 2}),
        output3: FunPipelineSync.call(shared.pipeline3, %FunPipelineSync{number: 2}),
        output4: FunPipelineSync.call(shared.pipeline3, %FunPipelineSync{number: 2})
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
