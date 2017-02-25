defmodule Flowex.Pipeline do
  defstruct module: nil, in_name: nil, out_name: nil, sup_pid: nil

  defmacro pipe(atom, count \\ 1) do
    quote do
      @pipes unquote({atom, count})
    end
  end

  defmacro __using__(_args) do
    quote do
      import Flowex.Pipeline

      Module.register_attribute __MODULE__, :pipes, accumulate: true
      @before_compile Flowex.Pipeline

      def start(opts \\ %{}) do
        Flowex.PipelineBuilder.start(__MODULE__, opts)
      end

      def stop(%Flowex.Pipeline{sup_pid: sup_pid}) do
        Flowex.PipelineBuilder.stop(sup_pid)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def pipes, do: Enum.reverse(@pipes)

      def run(%Flowex.Pipeline{in_name: in_name, out_name: out_name} = pipeline, struct = %__MODULE__{}) do
        pid = self()
        out_pid = link_to_consumer(out_name)
        ip = %Flowex.IP{struct: struct, requester: pid}
        GenServer.cast(out_name, {in_name, ip})
        receive do
          %Flowex.IP{requester: ^pid} = ip ->
            ip.struct
          {:EXIT, ^out_pid, reason} ->
            raise Flowex.PipelineError, pipeline: pipeline, message: reason
          smth ->
            reason = "Expected %Flowex.IP{}, received #{inspect smth}"
            raise Flowex.PipelineError, pipeline: pipeline, message: reason
        end
      end

      def cast(%Flowex.Pipeline{in_name: in_name, out_name: out_name} = pipeline, struct = %__MODULE__{}) do
        ip = %Flowex.IP{struct: struct, requester: false}
        GenServer.cast(out_name, {in_name, ip})
      end

      defp link_to_consumer(out_name) do
        out_pid = Process.whereis(out_name)
        Process.link(out_pid)
        Process.flag(:trap_exit, true)
        out_pid
      end
    end
  end
end
