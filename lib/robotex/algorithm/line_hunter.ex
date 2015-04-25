defmodule Robotex.Algorithm.LineHunter do
  use GenServer

  @speed 100
  @ms_per_degree 9

  def __required_features__, do: [:obstacle_sensors, :line_sensors, :locomotion]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def init(_) do
    obstacle_sensors = Robotex.Sensor.BinaryArray.read(:obstacle_sensors)
    line_sensors = Robotex.Sensor.BinaryArray.read(:line_sensors)
    {timeout, state} = react_all(:infinity, nil, :seeking, obstacle_sensors, line_sensors)

    Robotex.Sensor.BinaryArray.set_notification(:line_sensors, true)
    Robotex.Sensor.BinaryArray.set_notification(:obstacle_sensors, true)

    {:ok, %{obstacle_sensors: obstacle_sensors, line_sensors: line_sensors, state: state}, timeout}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_info({:robotex_binary_sensor_array, sensor_array, sensors_value}, data) do
    %{obstacle_sensors: obstacle_sensors, line_sensors: line_sensors, state: state} = update_data(sensor_array, sensors_value, data)
    {timeout, new_state} = react_all(:infinity, nil, state, obstacle_sensors, line_sensors)
    {:noreply, %{obstacle_sensors: obstacle_sensors, line_sensors: line_sensors, state: new_state}, timeout}
  end
  def handle_info(:timeout, %{obstacle_sensors: obstacle_sensors, line_sensors: line_sensors, state: state}) do
    {timeout, new_state} = react_all(:infinity, nil, state, obstacle_sensors, line_sensors)
    {:noreply, %{obstacle_sensors: obstacle_sensors, line_sensors: line_sensors, state: new_state}, timeout}
  end

  defp update_data(sensor_array, sensors_value, data) do
    {:registered_name, sensor_name} = Process.info(sensor_array, :registered_name)
    Map.put(data, sensor_name, sensors_value)
  end

  defp react_all(timeout, state, state, _obstacle_sensors, _line_sensors), do: {timeout, state}
  defp react_all(:infinity, _old_state, state, obstacle_sensors, line_sensors) do
    {timeout, new_state} = react(state, obstacle_sensors, line_sensors)
    react_all(timeout, state, new_state, obstacle_sensors, line_sensors)
  end
  defp react_all(timeout, _old_state, state, _obstacle_sensors, _line_sensors), do: {timeout, state}

  defp react(:seeking, obstacle_sensors, line_sensors) do
    cond do
      Enum.member?(line_sensors, true) ->
        {:infinity, :following}
      Enum.member?(obstacle_sensors, true) ->
        {:infinity, :avoiding}
      true ->
        Robotex.Actuator.DCMotorPair.forward(:locomotion, @speed)
        {:infinity, :seeking}
    end
  end
  defp react(:following, obstacle_sensors, line_sensors) do
    if Enum.member?(obstacle_sensors, true) do
      {:infinity, :avoiding}
    else
      do_follow_line(line_sensors)
    end
  end
  defp react(:avoiding, obstacle_sensors, _line_sensors) do
    #TODO: implement this, for now wait for
    #someone to remove obstacle
    Robotex.Actuator.DCMotorPair.halt(:locomotion)

    if Enum.member?(obstacle_sensors, true) do
      {:infinity, :avoiding}
    else
      {:infinity, :seeking}
    end
  end
  defp react({:recovering, phase}, _obstacle_sensors, line_sensors) do
    if Enum.member?(line_sensors, true) do
      {:infinity, :following}
    else
      do_recover(phase)
    end
  end

  defp do_follow_line(line_sensors) do
    case line_sensors do
      [true, true] ->
        Robotex.Actuator.DCMotorPair.forward(:locomotion, @speed)
        {:infinity, :following}
      [true, false] ->
        Robotex.Actuator.DCMotorPair.spin_left(:locomotion, @speed)
        {:infinity, :following}
      [false, true] ->
        Robotex.Actuator.DCMotorPair.spin_right(:locomotion, @speed)
        {:infinity, :following}
      [false, false] ->
        {:infinity, {:recovering, :init}}
    end
  end

  defp do_recover(:init) do
    Robotex.Actuator.DCMotorPair.spin_left(:locomotion, @speed)
    {@ms_per_degree * 110, {:recovering, :left}}
  end
  defp do_recover(:left) do
    Robotex.Actuator.DCMotorPair.spin_right(:locomotion, @speed)
    {@ms_per_degree * 220, {:recovering, :right}}
  end
  defp do_recover(:right) do
    Robotex.Actuator.DCMotorPair.spin_left(:locomotion, @speed)
    {@ms_per_degree * 110, {:recovering, :giveup}}
  end
  defp do_recover(:giveup) do
    {:infinity, :seeking}
  end
end
