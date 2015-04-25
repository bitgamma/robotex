defmodule Robotex.Robot do
  use Supervisor

  def start_link(robot, required_features, opts \\ []) do
    Supervisor.start_link(__MODULE__, [robot, required_features], opts)
  end

  def init([robot, required_features]) do
    children = robot_specs(robot, required_features)

    supervise(children, strategy: :one_for_one)
  end

  defp robot_specs(robot, features) do
    for feature <- features do
      {module, args} = robot.spec(feature)
      worker(module, args ++ [[name: feature]], [id: feature])
    end
  end
end
