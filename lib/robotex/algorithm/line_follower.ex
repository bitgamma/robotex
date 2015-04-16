defmodule Robotex.Algorithm.LineFollower do
  @speed 100

  def __required_features__, do: [:line_sensors, :locomotion]

  def run(%{line_sensors: sensors, locomotion: motors} = robot) do
    case Robotex.Sensor.BinaryArray.read(sensors) do
      [true, true] -> Robotex.Actuator.DCMotorPair.forward(motors, @speed)
      [true, false] -> Robotex.Actuator.DCMotorPair.spin_left(motors, @speed)
      [false, true] -> Robotex.Actuator.DCMotorPair.spin_right(motors, @speed)
      [false, false] -> Robotex.Actuator.DCMotorPair.spin_right(motors, @speed)
    end
    
    receive do
      :robotex_stop -> :ok
    after 0 ->
      run(robot)
    end
  end
end
