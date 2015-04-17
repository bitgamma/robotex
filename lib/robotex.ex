defmodule Robotex do
  def run(robot, algorithm) do
    required_features = apply(algorithm, :__required_features__, [])
    actual_features = apply(robot, :__features__, [])

    assert_requirements(required_features, actual_features)

    robot_map = init_robot(robot, required_features)
    algorithm_pid = spawn fn -> apply(algorithm, :run, [robot_map]) end

    keyboard = Robotex.KeyboardInput.start([keys: ["q"]])
    receive do
      {:keyboard_event, _} -> send(algorithm_pid, :robotex_stop)
    end

    stop_robot(robot, robot_map)

    Process.exit(keyboard, :kill)
  end

  defp init_robot(robot, features) do
    for feature <- features, into: %{}, do
      {:ok, initialized_feature} = apply(robot, :init, [feature])
      {feature, initialized_feature}
    end
  end

  defp stop_robot(robot, robot_map) do
    Enum.each(robot_map, fn(k, v) -> apply(robot, :stop, [k, v]) end)
  end

  defp assert_requirements(required_features, actual_features) do
    unless Enum.all?(required_features, fn(f) -> f in actual_features end) do
      raise ArgumentError, message: "This algorithm requires #{inspect(required_features)} but the selected robot only has #{inspect(actual_features)}"
    end
  end
end
