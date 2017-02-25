defmodule Flowex.PipelineError do
  defexception pipeline: nil, message: nil
end

defmodule Flowex.StageError do
  defexception message: nil, pipe: nil, struct: nil
end
