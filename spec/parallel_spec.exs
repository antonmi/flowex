defmodule PerallelSpec do
  use ESpec, async: true

  let :pipeline, do: ParallelPipeline.start

  def result(p) do
    ParallelPipeline.call(p, %ParallelPipeline{n: 1})
  end

  it "takes ~0.5 sec for 1 call" do
    func = fn -> result(pipeline()) end
    time = :timer.tc(func) |> elem(0)
    expect(time) |> to(be :>, 500_000)
  end

  context "4 parallel calls" do
    def func do
      p = pipeline()
      fn ->
        (1..4)
        |> Enum.map(fn(_i) -> Task.async(fn -> result(p) end) end)
        |> Enum.map(&Task.await/1)
      end
    end

    it "takes ~0.5 sec for 4 parallel calls" do
      time = :timer.tc(func()) |> elem(0)
      time |> should(be_between(500_000, 600_000))
    end
  end
end
