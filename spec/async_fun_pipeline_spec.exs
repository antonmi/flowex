defmodule AsyncFunPipelineSpec do
  use ESpec, async: true

  describe ".run" do
    let :pipeline, do: AsyncFunPipeline.start()

    before do
      pid = self()
      AsyncFunPipeline.cast(pipeline(), %AsyncFunPipeline{number: 2, pid: pid})
      {:shared, pid: pid}
    end

    it "receives result" do
      pid = shared.pid
      assert_receive(%AsyncFunPipeline{number: 3, pid: ^pid}, 100)
    end

    context "when running several times" do
      let :attempts, do: (1..3)

      it "returns the same results" do
        Enum.each(attempts(), fn(_) ->
          pid = self()
          AsyncFunPipeline.cast(pipeline(), %AsyncFunPipeline{number: 2, pid: pid})
          assert_receive(%AsyncFunPipeline{number: 3, pid: ^pid}, 100)
        end)
      end
    end
  end
end
