defmodule Flowex.PipelineError do
  defexception pipeline: nil, message: nil
end

defmodule Flowex.PipeError do
  defexception message: nil, pipe: nil, struct: nil
end
