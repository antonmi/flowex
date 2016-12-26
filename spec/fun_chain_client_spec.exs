defmodule FunChainClientSpec do
  use ESpec, async: true

  describe "FlowexClient" do
    let :chain, do: FunChain.start

    describe ".start" do
      let_ok :client_pid, do: Flowex.Client.start(chain())

      it do: assert(Process.alive?(client_pid()) == true)

      describe ".stop" do
        before do: Flowex.Client.stop(client_pid())

        it do: assert(Process.alive?(client_pid()) == false)
      end
    end


    describe ".run" do
      let_ok :client_pid, do: Flowex.Client.start(chain())
      let :result, do: Flowex.Client.run(client_pid(), %FunChain{})

      it do: expect(result().number) |> to(eq 4)

      context "when running several times" do
        let :attempts, do: (1..3)

        before do
          numbers = attempts()
          |> Enum.map(fn(_) -> Flowex.Client.run(client_pid(), %FunChain{}).number end)
          {:ok, numbers: numbers}
        end

        it "returns the same results" do
          expected = Enum.map(attempts(), fn(_) -> 4 end)
          expect(shared.numbers) |> to(eq expected)
        end
      end
    end

    describe ".run!" do
      let! :result, do: Flowex.Client.run!(chain(), %FunChain{})

      it do: expect(result().number) |> to(eq 4)

      context "when running several times" do
        let :attempts, do: (1..3)

        before do
          numbers = attempts()
          |> Enum.map(fn(_) -> Flowex.Client.run!(chain(), %FunChain{}).number end)
          {:ok, numbers: numbers}
        end

        it "returns the same results" do
          expected = Enum.map(attempts(), fn(_) -> 4 end)
          expect(shared.numbers) |> to(eq expected)
        end
      end
    end
  end
end
