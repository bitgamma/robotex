defmodule Robotex.Supervisor do
  use Supervisor

  def start_link(robot, algorithm, opts \\ []) do
    required_features = algorithm.__required_features__
    actual_features = robot.__features__
    assert_requirements(required_features, actual_features)

    Supervisor.start_link(__MODULE__, [robot, algorithm, required_features], opts)
  end

  def init([robot, algorithm, required_features]) do
    children = [
      supervisor(Robotex.Robot, [robot, required_features]),
      worker(Robotex.Algorithm, [algorithm])
    ]

    supervise(children, strategy: :one_for_one)
  end

  defp assert_requirements(required_features, actual_features) do
    unless Enum.all?(required_features, fn(f) -> f in actual_features end) do
      raise ArgumentError, message: "This algorithm requires #{inspect(required_features)} but the selected robot only has #{inspect(actual_features)}"
    end
  end
end
