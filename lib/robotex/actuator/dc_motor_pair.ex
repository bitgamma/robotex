defmodule Robotex.Actuator.DCMotorPair do
  use GenServer

  def start_link(left_opts, right_opts, opts \\ []) do
    GenServer.start_link(__MODULE__, [left_opts, right_opts], opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def forward(pid, speed) do
    GenServer.cast(pid, {:set_speed, speed, 0, speed, 0})
  end

  def reverse(pid, speed) do
    GenServer.cast(pid, {:set_speed, 0, speed, 0, speed})
  end

  def halt(pid) do
    GenServer.cast(pid, {:set_speed, 0, 0, 0, 0})
  end

  def spin_left(pid, speed) do
    GenServer.cast(pid, {:set_speed, 0, speed, speed, 0})
  end

  def spin_right(pid, speed) do
    GenServer.cast(pid, {:set_speed, speed, 0, 0, speed})
  end

  def turn_forward(pid, speed_left, speed_right) do
    GenServer.cast(pid, {:set_speed, speed_left, 0, speed_right, 0})
  end

  def turn_backward(pid, speed_left, speed_right) do
    GenServer.cast(pid, {:set_speed, 0, speed_left, 0, speed_right})
  end

  def init([left_opts, right_opts]) do
    {:ok, left} = Robotex.Actuator.DCMotor.start_link(left_opts)
    {:ok, right} = Robotex.Actuator.DCMotor.start_link(right_opts)
    {:ok, %{left: left, right: right}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:set_speed, left_fw, left_rv, right_fw, right_rv}, state = %{left: left, right: right}) do
    Robotex.Actuator.DCMotor.set_speed(left, left_fw, left_rv)
    Robotex.Actuator.DCMotor.set_speed(right, right_fw, right_rv)
    {:noreply, state}
  end
end
