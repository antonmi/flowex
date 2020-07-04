defmodule Flowex.Mixfile do
  use Mix.Project

  def project do
    [app: :flowex,
     version: "0.5.4",
     elixir: ">= 1.3.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     preferred_cli_env: [espec: :test],
     deps: deps(),
     description: description(),
     package: package(),
     source_url: "https://github.com/antonmi/flowex"
    ]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      {:gen_stage, "~> 1.0"},
      {:espec, "~> 1.8", only: :test},
      {:credo, "~> 1.4", only: [:dev, :test]},
      # Docs
      {:earmark, "~> 1.4", only: [:docs, :dev]},
      {:ex_doc, "~> 0.22", only: [:docs, :dev]}
    ]
  end

  defp description do
    "Flow-Based Programming with Elixir GenStage."
  end

  defp package do
   [
     files: ~w(lib mix.exs README.md),
     maintainers: ["Anton Mishchuk"],
     licenses: ["MIT"],
     links: %{"github" => "https://github.com/antonmi/flowex"}
   ]
  end
end
