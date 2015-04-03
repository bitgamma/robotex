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
    {:ok, obstacle_sensor_left} = Gpio.start_link(@obstacle_sensor_left, :input)
    {:ok, obstacle_sensor_right} = Gpio.start_link(@obstacle_sensor_right, :input)
    {:ok, line_sensor_left} = Gpio.start_link(@line_sensor_left, :input)
    {:ok, line_sensor_right} = Gpio.start_link(@line_sensor_right, :input)
    {:ok, motor_left_forward} = Robotex.SoftPWM.start_link(pin: @motor_left_forward)
    {:ok, motor_left_backward} = Robotex.SoftPWM.start_link(pin: @motor_left_backward)
    {:ok, motor_right_forward} = Robotex.SoftPWM.start_link(pin: @motor_right_forward)
    {:ok, motor_right_backward} = Robotex.SoftPWM.start_link(pin: @motor_right_backward)

    {:ok, %{obstacle_sensors: {obstacle_sensor_left, obstacle_sensor_right}, line_sensors: {line_sensor_left, line_sensor_right}, motors: {motor_left_forward, motor_left_backward, motor_right_forward, motor_right_backward}}}
  end

  def handle_call(:release, _from, state = %{obstacle_sensors: {obstacle_sensor_left, obstacle_sensor_right}, line_sensors: {line_sensor_left, line_sensor_right}, motors: {motor_left_forward, motor_left_backward, motor_right_forward, motor_right_backward}}) do
    Gpio.release(obstacle_sensor_left)
    Gpio.release(obstacle_sensor_right)
    Gpio.release(line_sensor_left)
    Gpio.release(line_sensor_right)
    Robotex.SoftPWM.release(motor_left_forward)
    Robotex.SoftPWM.release(motor_left_backward)
    Robotex.SoftPWM.release(motor_right_forward)
    Robotex.SoftPWM.release(motor_right_backward)

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
  def handle_call({:set_motors, speed_left_fw, speed_left_bw, speed_right_fw, speed_right_bw}, _form, state = %{motors: {motor_left_forward, motor_left_backward, motor_right_forward, motor_right_backward}}) do
    Robotex.SoftPWM.set_frequency_and_duty_cycle(motor_left_forward, speed_left_fw + 5, speed_left_fw)
    Robotex.SoftPWM.set_frequency_and_duty_cycle(motor_left_backward, speed_left_bw + 5, speed_left_bw)
    Robotex.SoftPWM.set_frequency_and_duty_cycle(motor_right_forward, speed_right_fw + 5, speed_right_fw)
    Robotex.SoftPWM.set_frequency_and_duty_cycle(motor_right_backward, speed_right_bw + 5, speed_right_bw)

    {:reply, :ok, state}
  end
  def handle_call(:get_distance, _from, state) do
    #TODO extract this in a separate module, requires more performant GPIO to actually work
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

    Gpio.set_int(sonar, :none)
    Gpio.release(sonar)

    elapsed = :timer.now_diff(stop, start) / 1_000_000

    # Distance pulse travelled in that time is time multiplied by the speed of sound (cm/s)
    distance = (elapsed * 34000) / 2

    {:reply, distance, state}
  end
end
