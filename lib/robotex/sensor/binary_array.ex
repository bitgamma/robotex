defmodule Robotex.Sensor.BinaryArray do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def read(pid) do
    GenServer.call(pid, :read)
  end

  def set_notification(pid, target \\ self, trueOrFalse)
  def set_notification(pid, target, true) do
    GenServer.call(pid, {:set_notification, target})
  end
  def set_notification(pid, _target, false) do
    GenServer.call(pid, {:set_notification, nil})
  end

  def init(opts) do
    sensor_list = Keyword.fetch!(opts, :sensors)
    max_update_rate = Keyword.get(opts, :max_update_rate, 1)

    sensors = for sensor <- sensor_list do
      Robotex.Sensor.Binary.set_notification(sensor, true)
      {sensor, Robotex.Sensor.Binary.read(sensor)}
    end

    {:ok, %{sensors: sensors, max_update_rate: max_update_rate, notified_pid: nil, send_timer: nil}}
  end

  def handle_call(:stop, _from, state = %{sensors: sensors}) do
    for {sensor, _} <- sensors, do: Robotex.Sensor.Binary.stop(sensor)
    {:stop, :normal, state}
  end
  def handle_call(:read, _from, state) do
    {:reply, read_values(state), state}
  end
  def handle_call({:set_notification, notified_pid}, _from, state) do
    {:reply, :ok, %{state | notified_pid: notified_pid}}
  end

  def handle_info({:robotex_binary_sensor, sensor, _time, value}, state) do
    new_state = state |> update_state(sensor, value) |> notify_listener
    {:noreply, new_state}
  end

  defp update_state(state = %{sensors: sensors}, updated_sensor, updated_value) do
    updated_sensors = for {sensor, value} <- sensors do
      if updated_sensor == sensor do
        {sensor, updated_value}
      else
        {sensor, value}
      end
    end

    %{state | sensors: updated_sensors}
  end

  defp notify_listener(state = %{notified_pid: nil}), do: state
  defp notify_listener(state = %{notified_pid: notified_pid, max_update_rate: max_update_rate, send_timer: timer}) do
    :erlang.cancel_timer(timer)
    new_timer = Process.send_after(notified_pid, {:robotex_binary_sensor_array, read_values(state)}, max_update_rate)

    %{state | send_timer: new_timer}
  end

  defp read_values(%{sensors: sensors}) do
    for {_, value} <- sensors, do: value
  end
end
