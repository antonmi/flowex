defmodule AsyncFunPipelineSpec do
  use ESpec, async: true

  describe ".run" do
    let :pipeline, do: FunPipelineCast.start()

    before do
      pid = self()
      FunPipelineCast.cast(pipeline(), %FunPipelineCast{number: 2, pid: pid})
      {:shared, pid: pid}
    end

    it "receives result" do
      assert_receive(3, 100)
    end

    context "when running several times" do
      let :attempts, do: (1..3)

      it "returns the same results" do
        Enum.each(attempts(), fn(_) ->
          pid = self()
          FunPipelineCast.cast(pipeline(), %FunPipelineCast{number: 2, pid: pid})
          assert_receive(3, 100)
        end)
      end
    end
  end
end
