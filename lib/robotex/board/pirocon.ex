defmodule Robotex.Board.Pirocon do
  use GenServer

  @motor_left_forward 10
  @motor_left_backward 9

  @motor_right_forward 8
  @motor_right_backward 7

  @obstacle_sensor_left 4
  @obstacle_sensor_right 17

  @line_sensor_left 18
  @line_sensor_right 27

  @sonar 14

  @servo_tilt 24
  @servo_pan 25

  def start_link do
    GenServer.start_link(__MODULE__, [parent: self])
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def read_obstacle_sensors(pid) do
    GenServer.call(pid, :read_obstacle_sensors)
  end

  def read_line_sensors(pid) do
    GenServer.call(pid, :read_line_sensors)
  end

  def get_distance(pid) do
    GenServer.call(pid, :get_distance)
  end

  def forward(pid, speed) when speed >= 0 and speed <= 100 do
    GenServer.call(pid, {:set_motors, speed, 0, speed, 0})
  end

  def backward(pid, speed) when speed >= 0 and speed <= 100 do
    GenServer.call(pid, {:set_motors, 0, speed, 0, speed})
  end

  def spin_left(pid, speed) when speed >= 0 and speed <= 100 do
    GenServer.call(pid, {:set_motors, 0, speed, speed, 0})
  end

  def spin_right(pid, speed) when speed >= 0 and speed <= 100 do
    GenServer.call(pid, {:set_motors, speed, 0, 0, speed})
  end

  def turn_forward(pid, speed_left, speed_right) when speed_left >= 0 and speed_left <= 100 and speed_right >= 0 and speed_right <= 100 do
    GenServer.call(pid, {:set_motors, speed_left, 0, speed_right, 0})
  end

  def turn_backward(pid, speed_left, speed_right) when speed_left >= 0 and speed_left <= 100 and speed_right >= 0 and speed_right <= 100 do
    GenServer.call(pid, {:set_motors, 0, speed_left, 0, speed_right})
  end

  def halt(pid) do
    GenServer.call(pid, {:set_motors, 0, 0, 0, 0})
  end

  def pan(pid, degrees) when degrees >= -90 and degrees <= 90 do
    GenServer.call(pid, {:set_servo, @servo_pan, degrees_to_pulsewidth(degrees)})
  end

  def tilt(pid, degrees) when degrees >= -90 and degrees <= 90 do
    GenServer.call(pid, {:set_servo, @servo_tilt, degrees_to_pulsewidth(degrees)})
  end

  def set_notify_on_obstacle_change(pid, trueOrFalse) do
    GenServer.call(pid, {:set_notification, :notify_on_obstacle, trueOrFalse})
  end

  def set_notify_on_line_change(pid, trueOrFalse) do
    GenServer.call(pid, {:set_notification, :notify_on_line, trueOrFalse})
  end

  defp degrees_to_pulsewidth(degrees) do
    round(500 + ((90 - degrees) * 2000 / 180))
  end

  def init(opts) do
    :ok = ExPigpio.set_mode(@motor_left_forward, :output)
    :ok = ExPigpio.set_mode(@motor_left_backward, :output)
    :ok = ExPigpio.set_mode(@motor_right_forward, :output)
    :ok = ExPigpio.set_mode(@motor_right_backward, :output)

    {:ok, _} = ExPigpio.set_pwm_range(@motor_left_forward, 100)
    {:ok, _} = ExPigpio.set_pwm_range(@motor_left_backward, 100)
    {:ok, _} = ExPigpio.set_pwm_range(@motor_right_forward, 100)
    {:ok, _} = ExPigpio.set_pwm_range(@motor_right_backward, 100)

    :ok = ExPigpio.set_mode(@obstacle_sensor_left, :input)
    :ok = ExPigpio.set_mode(@obstacle_sensor_right, :input)
    :ok = ExPigpio.set_mode(@line_sensor_left, :input)
    :ok = ExPigpio.set_mode(@line_sensor_right, :input)

    :ok = ExPigpio.add_alert(@obstacle_sensor_left, self)
    :ok = ExPigpio.add_alert(@obstacle_sensor_right, self)
    :ok = ExPigpio.add_alert(@line_sensor_left, self)
    :ok = ExPigpio.add_alert(@line_sensor_right, self)

    :ok = ExPigpio.set_mode(@servo_tilt, :output)
    :ok = ExPigpio.set_mode(@servo_pan, :output)

    parent = Keyword.fetch!(opts, :parent)

    {:ok, %{parent: parent, timers: %{@servo_tilt => nil, @servo_pan => nil}, notify_on_obstacle: false, notify_on_line: false}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end
  def handle_call(:read_obstacle_sensors, _from, state) do
    {:ok, left} = ExPigpio.read(@obstacle_sensor_left)
    {:ok, right} = ExPigpio.read(@obstacle_sensor_right)

    {:reply, {left == 0, right == 0}, state}
  end
  def handle_call(:read_line_sensors, _from, state) do
    {:ok, left} = ExPigpio.read(@line_sensor_left)
    {:ok, right} = ExPigpio.read(@line_sensor_right)

    {:reply, {left == 1, right == 1}, state}
  end
  def handle_call({:set_motors, speed_left_fw, speed_left_bw, speed_right_fw, speed_right_bw}, _form, state) do
    :ok = ExPigpio.set_pwm(@motor_left_forward, speed_left_fw)
    :ok = ExPigpio.set_pwm(@motor_left_backward, speed_left_bw)
    :ok = ExPigpio.set_pwm(@motor_right_forward, speed_right_fw)
    :ok = ExPigpio.set_pwm(@motor_right_backward, speed_right_bw)

    {:reply, :ok, state}
  end
  def handle_call({:set_servo, servo, pulsewidth}, _form, state = %{timers: timers}) do
    timer = Map.get(timers, servo)

    :timer.cancel(timer)
    :ok = ExPigpio.set_servo(servo, pulsewidth)
    {:ok, timer} = :timer.apply_after(2000, ExPigpio, :set_servo, [servo, 0])

    timers = Map.put(timers, servo, timer)
    {:reply, :ok, %{state | timers: timers}}
  end
  def handle_call(:get_distance, _from, state) do
    :ok = ExPigpio.set_mode(@sonar, :output)
    :ok = ExPigpio.write(@sonar, 1)
    ExPigpio.udelay(10)
    :ok = ExPigpio.write(@sonar, 0)

    :ok = ExPigpio.set_mode(@sonar, :input)

    :ok = ExPigpio.add_alert(@sonar, self)
    {start, stop} = receive_sonar_alerts(:next, Inf, Inf)
    :ok = ExPigpio.remove_alert(@sonar, self)

    distance = calculate_distance_cm(start, stop)
    {:reply, distance, state}
  end
  def handle_call({:set_notification, type, trueOrFalse}, _from, state) do
    {:reply, :ok, Map.put(state, type, trueOrFalse)}
  end

  def handle_info({:gpio_alert, @obstacle_sensor_left, level, time}, state = %{parent: parent, notify_on_obstacle: true}) do
    {:ok, right} = ExPigpio.read(@obstacle_sensor_right)
    send(parent, {:robotex_obstacle_change, time, level == 0, right == 0})
    {:noreply, state}
  end
  def handle_info({:gpio_alert, @obstacle_sensor_right, level, time}, state = %{parent: parent, notify_on_obstacle: true}) do
    {:ok, left} = ExPigpio.read(@obstacle_sensor_left)
    send(parent, {:robotex_obstacle_change, time, left == 0, level == 0})
    {:noreply, state}
  end
  def handle_info({:gpio_alert, @line_sensor_left, level, time}, state = %{parent: parent, notify_on_line: true}) do
    {:ok, right} = ExPigpio.read(@line_sensor_right)
    send(parent, {:robotex_line_change, time, level == 1, right == 1})
    {:noreply, state}
  end
  def handle_info({:gpio_alert, @line_sensor_right, level, time}, state = %{parent: parent, notify_on_line: true}) do
    {:ok, left} = ExPigpio.read(@line_sensor_left)
    send(parent, {:robotex_line_change, time, left == 1, level == 1})
    {:noreply, state}
  end
  def handle_info({:gpio_alert, _gpio, _level, _time}, state), do: {:noreply, state}

  defp receive_sonar_alerts(:stop, start, stop), do: {start, stop}
  defp receive_sonar_alerts(:next, start, stop) do
    receive do
      {:gpio_alert, @sonar, 1, time} -> receive_sonar_alerts(:next, time, stop)
      {:gpio_alert, @sonar, 0, time} -> receive_sonar_alerts(:next, start, time)
      after 50 -> receive_sonar_alerts(:stop, start, stop)
    end
  end

  defp calculate_distance_cm(start, stop) when (start == Inf) or (stop == Inf) or (stop < start), do: Inf
  defp calculate_distance_cm(start, stop), do: (((stop - start) * 340) / 2) / 10_000
end
