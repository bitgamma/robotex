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
    sensors_value = Robotex.Sensor.BinaryArray.read(:line_sensors)
    timeout = react(sensors_value)

    Robotex.Sensor.BinaryArray.set_notification(:line_sensors, true)
    {:ok, :ok, timeout}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_info({:robotex_binary_sensor_array, sensors_value}, :ok) do
    timeout = react(sensors_value)
    {:noreply, :ok, timeout}
  end
  def handle_info(:timeout, :ok) do
    Robotex.Actuator.DCMotorPair.spin_left(:locomotion, @speed)
    {:noreply, :ok, :infinity}
  end

  defp react(sensors_value) do
    case sensors_value do
      [true, true] ->
        Robotex.Actuator.DCMotorPair.forward(:locomotion, @speed)
        :infinity
      [true, false] ->
        Robotex.Actuator.DCMotorPair.spin_left(:locomotion, @speed)
        :infinity
      [false, true] ->
        Robotex.Actuator.DCMotorPair.spin_right(:locomotion, @speed)
        :infinity
      [false, false] ->
        Robotex.Actuator.DCMotorPair.spin_right(:locomotion, @speed)
        1000
    end
  end
end
