defmodule Robotex.Actuator.Servo do
  use GenServer

  def start_link(servo_opts, opts \\ []) do
    GenServer.start_link(__MODULE__, servo_opts, opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def rotate(pid, deg) when deg >= -90 and deg <= 90 do
    GenServer.cast(pid, {:set_pulsewidth, degrees_to_pulsewidth(deg)})
  end

  def init(opts) do
    Process.flag(:trap_exit, true)

    pin = Keyword.fetch!(opts, :pin)
    ExPigpio.set_mode(pin, :output)

    {:ok, %{pin: pin, timer: nil}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:set_pulsewidth, pulsewidth}, state = %{pin: pin, timer: timer}) do
    :timer.cancel(timer)
    ExPigpio.set_servo(pin, pulsewidth)
    {:ok, timer} = :timer.apply_after(2000, ExPigpio, :set_servo, [pin, 0])

    {:noreply, %{state | timer: timer}}
  end

  def terminate(_reason, %{pin: pin, timer: timer}) do
    :timer.cancel(timer)
    ExPigpio.set_servo(pin, 0)
    :ok
  end

  defp degrees_to_pulsewidth(deg) do
    round(500 + ((90 - deg) * 2000 / 180))
  end
end
