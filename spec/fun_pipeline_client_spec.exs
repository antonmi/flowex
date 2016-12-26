defmodule FunPipelineClientSpec do
  use ESpec, async: true

  describe "FlowexClient" do
    let :opts, do: %{a: :a, b: :b, c: :c}
    let :pipeline, do: FunPipeline.start(opts())

    describe ".start" do
      let_ok :client_pid, do: Flowex.Client.start(pipeline())

      it do: assert Process.alive?(client_pid()) == true

      describe ".stop" do
        before do: Flowex.Client.stop(client_pid())

        it do: assert Process.alive?(client_pid()) == false
      end
    end

    describe ".run" do
      let_ok :client_pid, do: Flowex.Client.start(pipeline())
      let :result, do: Flowex.Client.run(client_pid(), %FunPipeline{})

      it do: expect(result().number) |> to(eq 4)

      it "sets a, b, c" do
        assert result().a == :a
        assert result().b == :b
        assert result().c == :c
      end

      context "when running several times" do
        let :attempts, do: (1..3)

        before do
          numbers = attempts()
          |> Enum.map(fn(_) -> Flowex.Client.run(client_pid(), %FunPipeline{}).number end)
          {:ok, numbers: numbers}
        end

        it "returns the same results" do
          expected = Enum.map(attempts(), fn(_) -> 4 end)
          assert shared.numbers == expected
        end
      end
    end

    describe ".run!" do
      let! :result, do: Flowex.Client.run!(pipeline(), %FunPipeline{})

      it do: assert result().number ==  4

      it "sets a, b, c" do
        assert result().a == :a
        assert result().b == :b
        assert result().c == :c
      end

      context "when running several times" do
        let :attempts, do: (1..3)

        before do
          numbers = attempts()
          |> Enum.map(fn(_) -> Flowex.Client.run!(pipeline(), %FunPipeline{}).number end)
          {:ok, numbers: numbers}
        end

        it "returns the same results" do
          expected = Enum.map(attempts(), fn(_) -> 4 end)
          assert shared.numbers == expected
        end
      end
    end
  end
end
