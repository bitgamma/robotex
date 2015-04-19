defmodule Robotex.Sensor.BinaryArray do
  use GenServer

  def start_link(sensor_opts, opts \\ []) do
    GenServer.start_link(__MODULE__, sensor_opts, opts)
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
    {:ok, sensor_list} = Robotex.Sensor.Binary.start_link_multiple(opts)

    sensors = for sensor <- sensor_list do
      Robotex.Sensor.Binary.set_notification(sensor, true)
      {sensor, Robotex.Sensor.Binary.read(sensor)}
    end

    {:ok, %{sensors: sensors, notified_pid: nil}}
  end

  def handle_call(:stop, _from, state) do
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
  defp notify_listener(state = %{notified_pid: notified_pid}) do
    send(notified_pid, {:robotex_binary_sensor_array, self, read_values(state)})
    state
  end

  defp read_values(%{sensors: sensors}) do
    for {_, value} <- sensors, do: value
  end
end
