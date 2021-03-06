defmodule Robotex.Mixfile do
  use Mix.Project

  def project do
    [app: :robotex,
     version: "0.0.1",
     elixir: "~> 1.0",
     escript: escript,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :ex_pigpio]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:ex_pigpio, github: "briksoftware/ex_pigpio"}]
  end

  defp escript do
    [ main_module: Robotex.CLI ]
  end
end
