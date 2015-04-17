defmodule Robotex.Sensor.Sonar do
  use GenServer

  def start_link(sonar_opts, opts \\ []) do
    GenServer.start_link(__MODULE__, sonar_opts, opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def read(pid) do
    GenServer.call(pid, :read)
  end

  def init(opts) do
    pin = Keyword.fetch!(opts, :pin)

    {:ok, %{pin: pin}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end
  def handle_call(:read, _from, state = %{pin: pin}) do
    ExPigpio.set_mode(pin, :output)
    ExPigpio.write(pin, 1)
    ExPigpio.udelay(10)
    ExPigpio.write(pin, 0)

    ExPigpio.set_mode(pin, :input)
    ExPigpio.add_alert(pin, self)
    {start, stop} = receive_sonar_alerts(:next, Inf, Inf)
    ExPigpio.remove_alert(pin, self)

    {:reply, calculate_distance_cm(start, stop), state}
  end

  defp receive_sonar_alerts(:stop, start, stop), do: {start, stop}
  defp receive_sonar_alerts(:next, start, stop) do
    receive do
      {:gpio_alert, _pin, 1, time} -> receive_sonar_alerts(:next, time, stop)
      {:gpio_alert, _pin, 0, time} -> receive_sonar_alerts(:next, start, time)
      after 50 -> receive_sonar_alerts(:stop, start, stop)
    end
  end

  defp calculate_distance_cm(start, stop) when (start == Inf) or (stop == Inf) or (stop < start), do: Inf
  defp calculate_distance_cm(start, stop), do: (((stop - start) * 340) / 2) / 10_000
end
