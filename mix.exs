defmodule Meme.Mixfile do
  use Mix.Project

  def project do
    [
      app: :meme,
      version: "0.2.1",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Memoization (caching) of function calls",
      source_url: "https://github.com/timCF/meme/",
      package: [
        licenses: ["Apache 2.0"],
        maintainers: ["Ilja Tkachuk aka timCF"],
        links: %{
          "GitHub" => "https://github.com/timCF/meme/",
          "Author's home page" => "https://timcf.github.io/"
        }
      ],
      # Docs
      name: "Meme",
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger], mod: {Meme.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:cachex, "~> 3.1.1"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
end
