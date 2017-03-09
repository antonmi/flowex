defmodule SupervisedStartSpec do
  use ESpec, async: true

  let :opts, do: %{a: :a, b: :b, c: :c}

  let_ok :supervisor_pid, do: Supervisor.start_link([], strategy: :one_for_one)

  let :pipeline1, do: FunPipeline.supervised_start(supervisor_pid(), opts())
  let :pipeline2, do: FunPipeline.supervised_start(supervisor_pid(), opts())

  it "checks pipeline1" do
    output = FunPipeline.call(pipeline1(), %FunPipeline{number: 2})
    assert output.number == 3
  end

  it "checks pipeline2" do
    output = FunPipeline.call(pipeline2(), %FunPipeline{number: 2})
    assert output.number == 3
  end

  context "check supervisors" do
    let! :pipeline_sup_pids, do: [pipeline1().sup_pid(), pipeline2().sup_pid()]

    it "check supervisors" do
      Supervisor.which_children(supervisor_pid())
      |> Enum.each(fn({id, pid, type, [module]}) ->
        expect(id).to start_with("Flowex.Supervisor_")
        expect(pipeline_sup_pids()).to have(pid)
        expect(type).to eq(:supervisor)
        expect(module).to eq(Flowex.Supervisor)
      end)
    end
  end
end
