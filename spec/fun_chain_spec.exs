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
    let :opts, do: %{a: :a, b: :b, c: :c}
    let :chain, do: FunChain.start(opts())
    let :output, do: FunChain.run(chain(), %FunChain{})

    it do: assert output().number == 4

    it "sets a, b, c" do
      assert output().a == :a
      assert output().b == :b
      assert output().c == :c
    end

    context "when running several times" do
      let :attempts, do: (1..3)

      before do
        numbers = Enum.map(attempts(), fn(_) -> FunChain.run(chain(), %FunChain{}).number end)
        {:ok, numbers: numbers}
      end

      it "returns the same results" do
        expected = Enum.map(attempts(), fn(_) -> 4 end)
        assert shared.numbers == expected
      end
    end
  end
end
