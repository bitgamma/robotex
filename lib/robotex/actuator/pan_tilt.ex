defmodule Robotex.Actuator.PanTilt do
  use GenServer

  def start_link(pan_opts, tilt_opts, opts \\ []) do
    GenServer.start_link(__MODULE__, [pan_opts, tilt_opts], opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def pan(pid, degrees) do
    GenServer.cast(pid, {:pan, degrees})
  end

  def tilt(pid, degrees) do
    GenServer.cast(pid, {:tilt, degrees})
  end

  def pan_and_tilt(pid, pan_degrees, tilt_degrees) do
    GenServer.cast(pid, {:pan_and_tilt, pan_degrees, tilt_degrees})
  end

  def center(pid) do
    GenServer.cast(pid, {:pan_and_tilt, 0, 0})
  end

  def init([pan_opts, tilt_opts]) do
    {:ok, pan} = Robotex.Actuator.Servo.start_link(pan_opts)
    {:ok, tilt} = Robotex.Actuator.Servo.start_link(tilt_opts)
    {:ok, %{pan: pan, tilt: tilt}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:pan, pdeg}, state = %{pan: pan}) do
    Robotex.Actuator.Servo.rotate(pan, pdeg)
    {:noreply, state}
  end
  def handle_cast({:tilt, tdeg}, state = %{tilt: tilt}) do
    Robotex.Actuator.Servo.rotate(tilt, tdeg)
    {:noreply, state}
  end
  def handle_cast({:pan_and_tilt, pdeg, tdeg}, state = %{pan: pan, tilt: tilt}) do
    Robotex.Actuator.Servo.rotate(pan, pdeg)
    Robotex.Actuator.Servo.rotate(tilt, tdeg)
    {:noreply, state}
  end
end
