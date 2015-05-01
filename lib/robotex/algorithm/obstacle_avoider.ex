defmodule Robotex.Algorithm.ObstacleAvoider do
  use GenServer

  @speed 100

  def __required_features__, do: [:obstacle_sensors, :locomotion]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def init(_) do
    sensors_value = Robotex.Sensor.BinaryArray.read(:obstacle_sensors)
    react(sensors_value)

    Robotex.Sensor.BinaryArray.set_notification(:obstacle_sensors, true)
    {:ok, :ok}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_info({:robotex_binary_sensor_array, _, sensors_value}, :ok) do
    react(sensors_value)
    {:noreply, :ok}
  end

  defp react(sensors_value) do
    case sensors_value do
      [true, _] ->
        Robotex.Actuator.DCMotorPair.spin_right(:locomotion, @speed)
      [false, true] ->
        Robotex.Actuator.DCMotorPair.spin_left(:locomotion, @speed)
      [false, false] ->
        Robotex.Actuator.DCMotorPair.forward(:locomotion, @speed)
    end
  end
end
