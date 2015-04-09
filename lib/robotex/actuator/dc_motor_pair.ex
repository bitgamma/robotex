defmodule Robotex.Actuator.DCMotorPair do
  defstruct [left: nil, right: nil]

  defmacro is_valid(left, right) do
    quote do
      not (is_nil(unquote(left)) or is_nil(unquote(right)))
    end
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
