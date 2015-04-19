defmodule Robotex.Algorithm.ObstacleAvoider do
  use GenServer

  @speed 100
  @time_to_rotate_head 1000
  @head_rotation_degrees 60

  def __required_features__, do: [:sonar, :obstacle_sensors, :locomotion, :pan_tilt]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def init(_) do
    Robotex.Actuator.PanTilt.center(:pan_tilt)
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
      [true, true] ->
        Robotex.Actuator.DCMotorPair.halt(:locomotion)
        find_road
      [true, false] ->
        Robotex.Actuator.DCMotorPair.spin_right(:locomotion, @speed)
      [false, true] ->
        Robotex.Actuator.DCMotorPair.spin_left(:locomotion, @speed)
      [false, false] ->
        Robotex.Actuator.DCMotorPair.forward(:locomotion, @speed)
    end
  end

  defp find_road do
    left_distance = get_distance(-@head_rotation_degrees)
    right_distance = get_distance(@head_rotation_degrees)
    Robotex.Actuator.PanTilt.pan(:pan_tilt, 0)

    if left_distance > right_distance do
      Robotex.Actuator.DCMotorPair.spin_left(:locomotion, @speed)
    else
      Robotex.Actuator.DCMotorPair.spin_right(:locomotion, @speed)
    end
  end

  defp get_distance(deg) do
    Robotex.Actuator.PanTilt.pan(:pan_tilt, deg)
    :timer.sleep(@time_to_rotate_head)
    Robotex.Sensor.Sonar.read(:sonar)
  end
end
