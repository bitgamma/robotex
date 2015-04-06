defmodule Robotex.Actuator.DCMotor do
  use GenServer

  defmacro is_speed(speed) do
    quote do
      unquote(speed) >= 0 and unquote(speed) <= 100
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def forward(pid, speed) when is_speed(speed) do
    GenServer.cast(pid, {:set_speed, speed, 0})
  end

  def reverse(pid, speed) when is_speed(speed) do
    GenServer.cast(pid, {:set_speed, 0, speed})
  end

  def halt(pid, speed) do
    GenServer.cast(pid, {:set_speed, 0, 0})
  end

  def init(opts) do
    forward_pin = Keyword.fetch!(opts, :forward_pin)
    reverse_pin = Keyword.fetch!(opts, :reverse_pin)

    ExPigpio.set_mode(forward_pin, :output)
    ExPigpio.set_mode(reverse_pin, :output)

    ExPigpio.set_pwm_range(forward_pin, 100)
    ExPigpio.set_pwm_range(reverse_pin, 100)

    {:ok, %{forward_pin: forward_pin, reverse_pin: reverse_pin}}
  end

  def handle_call(:stop, _from, state) do
    set_speed(state, 0, 0)
    {:stop, :normal, state}
  end

  def handle_cast({:set_speed, speed_fw, speed_rv}, state) do
    set_speed(state, speed_fw, speed_rv)
    {:noreply, state}
  end

  defp set_speed(%{forward_pin: forward_pin, reverse_pin: reverse_pin}, speed_fw, speed_rv) do
    ExPigpio.set_pwm(forward_pin, speed_fw)
    ExPigpio.set_pwm(reverse_pin, speed_rv)
  end
end
