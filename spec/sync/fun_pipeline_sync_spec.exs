defmodule FunPipelineSyncSpec do
  use ESpec, async: true

  describe ".start" do
    let :pipeline, do: FunPipelineSync.start(%{start_options: :start_options})

    it "checks pipeline struct" do
      expect(pipeline()) |> to(be_struct Flowex.Pipeline)
      expect(pipeline().module) |> to(eq FunPipelineSync)
      expect(pipeline().in_name) |> to(be_atom())
      expect(pipeline().out_name) |> to(be_atom())
      expect(pipeline().sup_name) |> to(be_atom())
    end
  end

  describe ".stop" do
    let! :pipeline, do: FunPipelineSync.start
    let :sup_pid, do: Process.whereis(pipeline().sup_name)
    let! :pipe_pids do
      Supervisor.which_children(sup_pid()) |> Enum.map(fn({_id, pid, :worker, [_]}) -> pid end)
    end

    it "stops supervisor" do
      assert Process.alive?(sup_pid())
      FunPipelineSync.stop(pipeline())
      refute Process.alive?(sup_pid())
      Enum.each(pipe_pids(), &(refute Process.alive?(&1)))
    end
  end

  describe ".call" do
    let :opts, do: %{a: :a, b: :b, c: :c}
    let :pipeline, do: FunPipelineSync.start(opts())
    let :output, do: FunPipelineSync.call(pipeline(), %FunPipelineSync{number: 2})

    it do: assert output().number == 3

    it "sets a, b, c" do
      assert output().a == {:a, 1}
      assert output().b == {:b, 2}
      assert output().c == {:c, 3}
    end
  end
end
