defmodule WS.MixProject do
  use Mix.Project

  def project do
    [
      app: :ws,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    port = String.to_integer(System.get_env("PORT") || "4040")

    [
      extra_applications: [:crypto],
      mods: {WS.Server.Application, port}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
