defmodule FunPipelineSpec do
  use ESpec, async: true

  describe ".start" do
    let :pipeline, do: FunPipeline.start

    it "checks pipeline struct" do
      expect(pipeline()) |> to(be_struct Flowex.Pipeline)
      expect(pipeline().module) |> to(eq FunPipeline)
      expect(pipeline().in_name) |> to(be_atom())
      expect(pipeline().out_name) |> to(be_atom())
      expect(pipeline().sup_pid) |> to(be_pid())
    end
  end

  describe ".stop" do
    let! :pipeline, do: FunPipeline.start
    let :sup_pid, do: pipeline().sup_pid
    let! :pipe_pids do
      Supervisor.which_children(sup_pid()) |> Enum.map(fn({_id, pid, :worker, [_]}) -> pid end)
    end

    it "stops supervisor" do
      assert Process.alive?(sup_pid())
      FunPipeline.stop(pipeline())
      refute Process.alive?(sup_pid())
      Enum.each(pipe_pids(), &(refute Process.alive?(&1)))
    end
  end

  describe ".call" do
    let :opts, do: %{a: :a, b: :b, c: :c}
    let :pipeline, do: FunPipeline.start(opts())
    let :output, do: FunPipeline.call(pipeline(), %FunPipeline{number: 2})

    it do: assert output().number == 3

    it "sets a, b, c" do
      assert output().a == :a
      assert output().b == :b
      assert output().c == :c
    end

    context "when running several times" do
      let :attempts, do: (1..3)

      before do
        numbers = Enum.map(attempts(), fn(_) ->
          FunPipeline.call(pipeline(), %FunPipeline{number: 2}).number
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
