defmodule Robotex.Algorithm.LineFollower do
  use GenServer

  @speed 100

  def __required_features__, do: [:line_sensors, :locomotion]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def init(_) do
    sensor_values = Robotex.Sensor.BinaryArray.read(:line_sensors)
    react(sensor_values)

    Robotex.Sensor.BinaryArray.set_notification(:line_sensors, true)
    {:ok, sensor_values}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_info({:robotex_binary_sensor_array, sensors_value}, _from, _state) do
    react(sensors_value)
    {:noreply, sensors_value}
  end

  defp react(sensors_value) do
    case sensors_value do
      [true, true] -> Robotex.Actuator.DCMotorPair.forward(:locomotion, @speed)
      [true, false] -> Robotex.Actuator.DCMotorPair.spin_left(:locomotion, @speed)
      [false, true] -> Robotex.Actuator.DCMotorPair.spin_right(:locomotion, @speed)
      [false, false] -> Robotex.Actuator.DCMotorPair.spin_right(:locomotion, @speed)
    end
  end
end
