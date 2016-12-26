defmodule FunChainSpec do
  use ESpec, async: true

  describe ".start" do
    let :chain, do: FunChain.start

    describe "chain struct" do
      it do: expect(chain()) |> to(be_struct Flowex.Chain)
      it do: expect(chain().module) |> to(eq FunChain)
      it do: expect(chain().in_pid) |> to(be_pid())
      it do: expect(chain().out_pid) |> to(be_pid())

      xit do: expect(chain().sup_pid) |> to(be_pid())
    end
  end

  describe ".stop" do
    xit do: "not implemented yet"
  end

  describe ".run" do
    let :chain, do: FunChain.start
    let :output, do: FunChain.run(chain(), %FunChain{})

    it do: expect(output().number) |> to(eq 4)

    context "when running several times" do
      let :attempts, do: (1..3)

      before do
        numbers = Enum.map(attempts(), fn(_) -> FunChain.run(chain(), %FunChain{}).number end)
        {:ok, numbers: numbers}
      end

      it "returns the same results" do
        expected = Enum.map(attempts(), fn(_) -> 4 end)
        expect(shared.numbers) |> to(eq expected)
      end
    end
  end
end
