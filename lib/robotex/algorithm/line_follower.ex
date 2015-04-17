defmodule Robotex.Algorithm.LineFollower do
  @speed 100

  def __required_features__, do: [:line_sensors, :locomotion]

  def run(robot = %{line_sensors: line_sensors, locomotion: locomotion}) do
    case Robotex.Sensor.BinaryArray.read(line_sensors) do
      [true, true] -> Robotex.Actuator.DCMotorPair.forward(locomotion, @speed)
      [true, false] -> Robotex.Actuator.DCMotorPair.spin_left(locomotion, @speed)
      [false, true] -> Robotex.Actuator.DCMotorPair.spin_right(locomotion, @speed)
      [false, false] -> Robotex.Actuator.DCMotorPair.spin_right(locomotion, @speed)
    end

    :timer.sleep(10)
    run(robot)
  end
end
