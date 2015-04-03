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

  def release(pid) do
    GenServer.call(pid, :release)
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

  def init(_) do
    {:ok, obstacle_sensor_left} = Gpio.start_link(@obstacle_sensor_left, :input)
    {:ok, obstacle_sensor_right} = Gpio.start_link(@obstacle_sensor_right, :input)
    {:ok, line_sensor_left} = Gpio.start_link(@line_sensor_left, :input)
    {:ok, line_sensor_right} = Gpio.start_link(@line_sensor_right, :input)

    {:ok, %{obstacle_sensors: {obstacle_sensor_left, obstacle_sensor_right}, line_sensors: {line_sensor_left, line_sensor_right}}}
  end

  def handle_call(:release, _from, state = %{obstacle_sensors: {obstacle_sensor_left, obstacle_sensor_right}, line_sensors: {line_sensor_left, line_sensor_right}}) do
    Gpio.release(obstacle_sensor_left)
    Gpio.release(obstacle_sensor_right)
    Gpio.release(line_sensor_left)
    Gpio.release(line_sensor_right)

    {:stop, :normal, state}
  end
  def handle_call(:read_obstacle_sensors, _from, state = %{obstacle_sensors: {obstacle_sensor_left, obstacle_sensor_right}}) do
    left = Gpio.read(obstacle_sensor_left) == 0
    right = Gpio.read(obstacle_sensor_right) == 0

    {:reply, {left, right}, state}
  end
  def handle_call(:read_line_sensors, _from, state = %{line_sensors: {line_sensor_left, line_sensor_right}}) do
    left = Gpio.read(line_sensor_left) == 1
    right = Gpio.read(line_sensor_right) == 1

    {:reply, {left, right}, state}
  end
  def handle_call(:get_distance, _from, state) do
    {:ok, sonar} = Gpio.start_link(@sonar, :output)
    Gpio.write(sonar, 1)
    Robotex.Util.usleep(10)
    Gpio.write(sonar, 0)

    Gpio.release(sonar)
    {:ok, sonar} = Gpio.start_link(@sonar, :input)

    Gpio.set_int(sonar, :rising)

    start = receive do
      {:gpio_interrupt, @sonar, :rising} -> :erlang.now
      after 100 -> :erlang.now
    end

    Gpio.set_int(sonar, :falling)

    stop = receive do
      {:gpio_interrupt, @sonar, :falling} -> :erlang.now
      after 100 -> :erlang.now
    end

    elapsed = :timer.now_diff(stop, start) / 1_000_000

    # Distance pulse travelled in that time is time multiplied by the speed of sound (cm/s)
    distance = (elapsed * 34000) / 2

    {:reply, distance, state}
  end
end
