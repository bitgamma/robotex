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

  def start_link do
    GenServer.start_link(__MODULE__, [])
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

  def stop(pid) do
    GenServer.call(pid, {:set_motors, 0, 0, 0, 0})
  end

  def init(_) do
    :ok = ExPigpio.set_mode(@motor_left_forward, :output)
    :ok = ExPigpio.set_mode(@motor_left_backward, :output)
    :ok = ExPigpio.set_mode(@motor_right_forward, :output)
    :ok = ExPigpio.set_mode(@motor_right_backward, :output)

    :ok = ExPigpio.set_pwm_range(@motor_left_forward, 100)
    :ok = ExPigpio.set_pwm_range(@motor_left_backward, 100)
    :ok = ExPigpio.set_pwm_range(@motor_right_forward, 100)
    :ok = ExPigpio.set_pwm_range(@motor_right_backward, 100)

    :ok = ExPigpio.set_mode(@obstacle_sensor_left, :input)
    :ok = ExPigpio.set_mode(@obstacle_sensor_right, :input)
    :ok = ExPigpio.set_mode(@line_sensor_left, :input)
    :ok = ExPigpio.set_mode(@line_sensor_right, :input)

    {:ok, :ok}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end
  def handle_call(:read_obstacle_sensors, _from, state) do
    left = ExPigpio.read(@obstacle_sensor_left) == 0
    right = ExPigpio.read(@obstacle_sensor_right) == 0

    {:reply, {left, right}, state}
  end
  def handle_call(:read_line_sensors, _from, state) do
    left = ExPigpio.read(@line_sensor_left) == 1
    right = ExPigpio.read(@line_sensor_right) == 1

    {:reply, {left, right}, state}
  end
  def handle_call({:set_motors, speed_left_fw, speed_left_bw, speed_right_fw, speed_right_bw}, _form, state) do
    ExPigpio.set_pwm(@motor_left_forward, speed_left_fw)
    ExPigpio.set_pwm(@motor_left_backward, speed_left_bw)
    ExPigpio.set_pwm(@motor_right_forward, speed_right_fw)
    ExPigpio.set_pwm(@motor_right_backward, speed_right_bw)

    {:reply, :ok, state}
  end
  def handle_call(:get_distance, _from, state) do
    :ok = ExPigpio.set_mode(@sonar, :output)
    :ok = ExPigpio.write(@sonar, 1)
    ExPigpio.udelay(10)
    :ok = ExPigpio.write(@sonar, 0)

    :ok = ExPigpio.set_mode(@sonar, :output)

    ExPigpio.add_alert(@sonar, self)

    start = receive do
      {:gpio_alert, @sonar, 1, _} -> :os.timestamp
      after 100 -> :os.timestamp
    end

    stop = receive do
      {:gpio_alert, @sonar, 0, _} -> :os.timestamp
      after 100 -> :os.timestamp
    end

    ExPigpio.remove_alert(@sonar, self)

    elapsed = :timer.now_diff(stop, start) / 1_000_000

    # Distance pulse travelled in that time is time multiplied by the speed of sound (cm/s)
    distance = (elapsed * 34000) / 2

    {:reply, distance, state}
  end
end
