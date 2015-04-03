defmodule Robotex.SoftPWM do
  def start_link(opts) do
    {:ok, state} = init(opts)
    {:ok, spawn_link(__MODULE__, :run, [state])}
  end

  def release(pid) do
    send pid, :release
    :ok
  end

  def set_duty_cycle(pid, duty_cycle) do
    send pid, {:duty_cycle, duty_cycle}
    :ok
  end

  def set_frequency(pid, frequency) do
    send pid, {:frequency, frequency}
    :ok
  end

  def run(state = %{timings: {0, _}}) do
    {action, _, state} = receive do
      msg ->
        handle_call(msg, self, state)
    end

    next(action, state)
  end

  def run(state = %{channel: channel, timings: {high_time, low_time}}) do
    Gpio.write(channel, 1)
    Robotex.Util.usleep(high_time)
    Gpio.write(channel, 0)
    Robotex.Util.usleep(low_time)

    {action, _, state} = receive do
      msg ->
        handle_call(msg, self, state)
      after 0 ->
        {:reply, :ok, state}
    end

    next(action, state)
  end

  defp next(:stop, _), do: :stop
  defp next(_, state), do: run(state)

  def init(opts) do
    pin = Keyword.fetch!(opts, :pin)
    duty_cycle = Keyword.get(opts, :duty_cycle, 0)
    frequency = Keyword.get(opts, :frequency, 0)

    {:ok, channel} = Gpio.start_link(pin, :output)
    {:ok, %{channel: channel, frequency: frequency, duty_cycle: duty_cycle, timings: calculate_timings_usec(frequency, duty_cycle)}}
  end
  def handle_call(:release, _from, state = %{channel: channel}) do
    Gpio.release(channel)
    {:stop, :normal, state}
  end
  def handle_call({:duty_cycle, duty_cycle}, _from, state = %{frequency: frequency}) do
    {:reply, :ok, %{state | duty_cycle: duty_cycle, timings: calculate_timings_usec(frequency, duty_cycle)}}
  end
  def handle_call({:frequency, frequency}, _from, state = %{duty_cycle: duty_cycle}) do
    {:reply, :ok, %{state | frequency: frequency, timings: calculate_timings_usec(frequency, duty_cycle)}}
  end

  defp calculate_timings_usec(0, _), do: {0, 1000}
  defp calculate_timings_usec(_, 0), do: {0, 1000}
  defp calculate_timings_usec(frequency, duty_cycle) do
    duration_usec = (1.0 / frequency) * 1_000_000
    high_duration_usec = (duration_usec / 100) * duty_cycle
    {Float.floor(high_duration_usec), Float.floor(duration_usec - high_duration_usec)}
  end
end
