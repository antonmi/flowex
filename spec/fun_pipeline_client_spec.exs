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
      let :result, do: Flowex.Client.run(client_pid(), %FunPipeline{number: 2})

      it do: expect(result().number) |> to(eq 3)

      it "sets a, b, c" do
        assert result().a == :a
        assert result().b == :b
        assert result().c == :c
      end

      context "when running several times" do
        let :attempts, do: (1..3)

        before do
          numbers = attempts()
          |> Enum.map(fn(_) ->
            Flowex.Client.run(client_pid(), %FunPipeline{number: 2}).number
          end)
          {:ok, numbers: numbers}
        end

        it "returns the same results" do
          expected = Enum.map(attempts(), fn(_) -> 3 end)
          assert shared.numbers == expected
        end
      end
    end

    describe ".cast" do
      let :pipeline, do: AsyncFunPipeline.start()
      let_ok :client_pid, do: Flowex.Client.start(pipeline())

      before do
        pid = self()
        Flowex.Client.cast(client_pid(),  %AsyncFunPipeline{number: 2, pid: pid})
        {:shared, pid: pid}
      end

      it "receives result" do
        pid = shared.pid
        assert_receive(%AsyncFunPipeline{number: 3, pid: ^pid}, 100)
      end
    end

    describe ".run!" do
      let! :result, do: Flowex.Client.run!(pipeline(), %FunPipeline{number: 2})

      it do: assert result().number ==  3

      it "sets a, b, c" do
        assert result().a == :a
        assert result().b == :b
        assert result().c == :c
      end

      context "when running several times" do
        let :attempts, do: (1..3)

        before do
          numbers = attempts()
          |> Enum.map(fn(_) ->
            Flowex.Client.run!(pipeline(), %FunPipeline{number: 2}).number
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
end
