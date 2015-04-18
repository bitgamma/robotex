defmodule Robotex.Robot.Initio do
  @motor_left_forward 10
  @motor_left_reverse 9

  @motor_right_forward 8
  @motor_right_reverse 7

  @obstacle_sensor_left 4
  @obstacle_sensor_right 17

  @line_sensor_left 18
  @line_sensor_right 27

  @sonar 14

  @servo_tilt 24
  @servo_pan 25

  def __features__, do: [:sonar, :obstacle_sensors, :line_sensors, :locomotion, :pan_tilt]

  def spec(:sonar), do: {Robotex.Sensor.Sonar, [[pin: @sonar]]}
  def spec(:obstacle_sensors), do: {Robotex.Sensor.BinaryArray, [[pins: [@obstacle_sensor_left, @obstacle_sensor_right], logic_high: 0]]}
  def spec(:line_sensors), do: {Robotex.Sensor.BinaryArray, [[pins: [@line_sensor_left, @line_sensor_right]]]}
  def spec(:locomotion), do: {Robotex.Actuator.DCMotorPair, [[forward_pin: @motor_left_forward, reverse_pin: @motor_left_reverse], [forward_pin: @motor_right_forward, reverse_pin: @motor_right_reverse]]}
  def spec(:pan_tilt), do: {Robotex.Actuator.PanTilt, [[pin: @servo_pan], [pin: @servo_tilt]]}
end
