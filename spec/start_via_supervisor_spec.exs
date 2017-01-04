defmodule StartViaSupervisorSpec do
  use ESpec

  # Supervisor.count_children(pid)

  xit "affa " do
    import Supervisor.Spec
    id = String.to_atom("Flowex.Producer #{inspect make_ref()}")
    children = [worker(Flowex.Producer, [nil, [name: id]] , [id: id])]

    {:ok, sup} = Supervisor.start_link(children, strategy: :one_for_one)

    assert Process.alive?(sup)

    [{id, in_producer, :worker, [Flowex.Producer]}] = Supervisor.which_children(sup)

    assert Process.alive?(in_producer)
    # IO.inspect Process.register(in_producer, :aaaa)
    IO.inspect(GenServer.whereis(id))

    opts =  %{a: :a, b: :b, c: :c}

    w = worker(Flowex.Stage, [{FunPipeline, :add_one, opts, [id]}, [name: :add_one_name]], [id: {FunPipeline, :add_one, 1}])
    {:ok, _add_one} = Supervisor.start_child(sup, w)

    # w = worker(Flowex.Stage, [{FunPipeline, :mult_by_two, opts, [:add_one_name]}, [name: :mult_by_two_name]], [id: {FunPipeline, :mult_by_two, 1}])
    # {:ok, mult_by_two} = Supervisor.start_child(sup, w)
    # #
    # w = worker(Flowex.Stage, [{FunPipeline, :minus_three, opts, [:mult_by_two_name]}, [name: :minus_three_name]], [id: {FunPipeline, :minus_three, 1}])
    # {:ok, minus_three} = Supervisor.start_child(sup, w)

    w = worker(Flowex.Consumer, [[:add_one_name], [name: :consumer_name]])
    {:ok, _out_consumer} = Supervisor.start_child(sup, w)

    Experimental.GenStage.demand(in_producer, :forward)


    pipeline = %Flowex.Pipeline{module: __MODULE__, in_name: id, out_name: :consumer_name, sup_pid: sup}

    expect(FunPipeline.run(pipeline, %FunPipeline{number: 2}).number).to eq(3)


    IO.inspect("Start killing.............")
    pid = Process.whereis(:add_one_name)
    Process.exit(pid, :kill)
    Process.sleep(6000)

    expect(FunPipeline.run(pipeline, %FunPipeline{number: 3}).number).to eq(4)


    IO.inspect("Start killing.............")
    pid = Process.whereis(:add_one_name)
    IO.inspect(pid)
    Process.exit(pid, :kill)
    Process.sleep(1000)

    expect(FunPipeline.run(pipeline, %FunPipeline{number: 3}).number).to eq(4)



  end
end
