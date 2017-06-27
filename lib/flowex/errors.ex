defmodule Flowex.PipelineError do
  defexception pipeline: nil, message: nil
end

defmodule Flowex.PipeError do
  defexception error: nil, message: nil, pipe: nil, struct: nil
end
