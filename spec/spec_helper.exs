ESpec.configure fn(config) ->
  config.before fn(tags) ->
    {:shared, hello: :world, tags: tags}
  end

  config.finally fn(_shared) ->
    :ok
  end
end

Code.require_file("spec/support/fun_pipeline.ex")
