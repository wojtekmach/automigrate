defmodule Automigrate.MixProject do
  use Mix.Project

  def project() do
    [
      app: :automigrate,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps() do
    [
      {:ecto, "~> 3.0-dev", github: "elixir-ecto/ecto"},
      {:postgrex, ">= 0.0.0", override: true, only: :test}
    ]
  end
end
