defmodule Robotex.Actuator.DCMotorPair do
  defstruct [left: nil, right: nil]

  defmacro is_valid(left, right) do
    quote do
      not (is_nil(unquote(left)) or is_nil(unquote(right)))
    end
  end

  def start_link_motors(left_opts, right_opts) do
    {:ok, left} = Robotex.Actuator.DCMotor.start_link(left_opts)
    {:ok, right} = Robotex.Actuator.DCMotor.start_link(right_opts)
    {:ok, %Robotex.Actuator.DCMotorPair{left: left, right: right}}
  end

  def stop_motors(%Robotex.Actuator.DCMotorPair{left: left, right: right}) do
    Robotex.Actuator.DCMotor.stop(left)
    Robotex.Actuator.DCMotor.stop(right)
  end

  def forward(%Robotex.Actuator.DCMotorPair{left: left, right: right}, speed) when is_valid(left, right) do
    Robotex.Actuator.DCMotor.forward(left, speed)
    Robotex.Actuator.DCMotor.forward(right, speed)
  end

  def reverse(%Robotex.Actuator.DCMotorPair{left: left, right: right}, speed) when is_valid(left, right) do
    Robotex.Actuator.DCMotor.reverse(left, speed)
    Robotex.Actuator.DCMotor.reverse(right, speed)
  end

  def halt(%Robotex.Actuator.DCMotorPair{left: left, right: right}) when is_valid(left, right) do
    Robotex.Actuator.DCMotor.halt(left)
    Robotex.Actuator.DCMotor.halt(right)
  end

  def spin_left(%Robotex.Actuator.DCMotorPair{left: left, right: right}, speed) when is_valid(left, right) do
    Robotex.Actuator.DCMotor.reverse(left, speed)
    Robotex.Actuator.DCMotor.forward(right, speed)
  end

  def spin_right(%Robotex.Actuator.DCMotorPair{left: left, right: right}, speed) when is_valid(left, right) do
    Robotex.Actuator.DCMotor.forward(left, speed)
    Robotex.Actuator.DCMotor.reverse(right, speed)
  end

  def turn_forward(%Robotex.Actuator.DCMotorPair{left: left, right: right}, speed_left, speed_right) when is_valid(left, right) do
    Robotex.Actuator.DCMotor.forward(left, speed_left)
    Robotex.Actuator.DCMotor.forward(right, speed_right)
  end

  def turn_backward(%Robotex.Actuator.DCMotorPair{left: left, right: right}, speed_left, speed_right) when is_valid(left, right) do
    Robotex.Actuator.DCMotor.reverse(left, speed_left)
    Robotex.Actuator.DCMotor.reverse(right, speed_right)
  end
end
