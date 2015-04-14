defmodule Robotex.Sensor.Binary do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def start_link_multiple(opts) do
    {pins, rest_opts} = Keyword.pop(opts, :pins)

    sensors = for pin <- pins do
       {:ok, sensor} = start_link(Keyword.put(rest_opts, :pin, pin))
       sensor
    end

    {:ok, sensors}
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def read(pid) do
    GenServer.call(pid, :read)
  end

  def set_notification(pid, target \\ self, trueOrFalse) do
    GenServer.call(pid, {:set_notification, target, trueOrFalse})
  end

  def init(opts) do
    pin = Keyword.fetch!(opts, :pin)
    logic_high = Keyword.get(opts, :logic_high, 1)

    ExPigpio.set_mode(pin, :input)

    {:ok, %{pin: pin, logic_high: logic_high, notified_pid: nil}}
  end

  def handle_call(:stop, _from, state = %{pin: pin, notified_pid: notified_pid}) do
    if notified_pid != nil do
      ExPigpio.remove_alert(pin, self)
    end

    {:stop, :normal, state}
  end
  def handle_call(:read, _from, state = %{pin: pin, logic_high: logic_high}) do
    {:ok, level} = ExPigpio.read(pin)

    {:reply, level == logic_high, state}
  end
  def handle_call({:set_notification, notified_pid, true}, _from, state = %{pin: pin, notified_pid: previous_pid}) do
    if previous_pid == nil do
      ExPigpio.add_alert(pin, self)
    end

    {:reply, :ok, %{state | notified_pid: notified_pid}}
  end
  def handle_call({:set_notification, _, false}, _from, state = %{pin: pin, notified_pid: previous_pid}) do
    if previous_pid != nil do
      ExPigpio.remove_alert(pin, self)
    end

    {:reply, :ok, %{state | notified_pid: nil}}
  end

  def handle_info({:gpio_alert, pin, level, time}, state = %{pin: pin, notified_pid: notified_pid, logic_high: logic_high}) do
    send(notified_pid, {:robotex_binary_sensor, self, time, level == logic_high})

    {:noreply, state}
  end
end
