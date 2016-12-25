defmodule FunChain do
  use Flowex.Chain

  component :init_data, 1
  component :add_one, 2
  component :multiply_by_2, 2

  def init_data(data) do
    Map.put(data, :number, 1)
  end

  def add_one(data) do
    # Process.sleep(1000)
    # IO.inspect("add_one: #{inspect self()}")
    new_number = data.number + 1
    %{data | number: new_number}
  end

  def multiply_by_2(data) do
    # Process.sleep(1000)
    # IO.inspect("multiply_by_2: #{inspect self()}")
    new_number = data.number * 2
    %{data | number: new_number}
  end
end
