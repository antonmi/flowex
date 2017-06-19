ESpec.configure fn(config) ->
  config.before fn(tags) ->
    {:shared, hello: :world, tags: tags}
  end

  config.finally fn(_shared) ->
    :ok
  end
end

Code.require_file("spec/support/fun_pipeline.ex")
Code.require_file("spec/support/fun_pipeline_cast.ex")
Code.require_file("spec/support/module_pipeline.ex")
Code.require_file("spec/support/interface_pipeline.ex")
Code.require_file("spec/support/init_opts_pipeline.ex")
Code.require_file("spec/support/parallel_pipeline.ex")
Code.require_file("spec/support/fun_pipeline_sync.ex")
Code.require_file("spec/support/module_pipeline_sync.ex")
