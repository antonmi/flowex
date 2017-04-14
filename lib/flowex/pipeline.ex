defmodule Flowex.Pipeline do
  @moduledoc "Defines macros for pipeline creating"

  defstruct module: nil, in_name: nil, out_name: nil, sup_pid: nil

  defmacro pipe(atom, count \\ 1) do
    quote do
      @pipes {unquote(atom), unquote(count), :pipe}
    end
  end

  defmacro error_pipe(atom, count \\ 1) do
    quote do
      @error_pipe {unquote(atom), unquote(count), :error_pipe}
    end
  end

  defmacro __using__(_args) do
    quote do
      import Flowex.Pipeline
      alias Flowex.PipelineBuilder

      Module.register_attribute __MODULE__, :pipes, accumulate: true
      Module.register_attribute __MODULE__, :error_pipe, accumulate: false
      @error_pipe {:handle_error, 1, :error_pipe}

      @before_compile Flowex.Pipeline

      def start(opts \\ %{}) do
        PipelineBuilder.start(__MODULE__, opts)
      end

      def supervised_start(pid, opts \\ %{}) do
        PipelineBuilder.supervised_start(__MODULE__, pid, opts)
      end

      def stop(%Flowex.Pipeline{sup_pid: sup_pid}) do
        PipelineBuilder.stop(sup_pid)
      end

      def handle_error(error, _struct, _opts) do
        raise error
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def pipes, do: Enum.reverse(@pipes)
      def error_pipe, do: @error_pipe

      def call(pipeline = %Flowex.Pipeline{in_name: in_name, out_name: out_name}, struct = %__MODULE__{}) do
        pid = self()
        ref = Process.monitor(out_name)
        ip = %Flowex.IP{struct: Map.delete(struct, :__struct__), requester: pid}

        GenServer.cast(out_name, {in_name, ip})

        receive do
          %Flowex.IP{requester: ^pid} = ip ->
            Process.demonitor(ref)
            struct(%__MODULE__{}, ip.struct)
          {:DOWN, ^ref, _, _, reason} ->
            raise Flowex.PipelineError, pipeline: pipeline, message: reason
          smth ->
            reason = "Expected %Flowex.IP{}, received #{inspect smth}"
            raise Flowex.PipelineError, pipeline: pipeline, message: reason
        end
      end

      def cast(pipeline = %Flowex.Pipeline{in_name: in_name, out_name: out_name}, struct = %__MODULE__{}) do
        ip = %Flowex.IP{struct: Map.delete(struct, :__struct__), requester: false}
        GenServer.cast(out_name, {in_name, ip})
      end
    end
  end
end
