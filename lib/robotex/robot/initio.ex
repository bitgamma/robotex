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

  def init(:sonar), do: Robotex.Sensor.Sonar.start_link(pin: @sonar)
  def init(:obstacle_sensors), do: Robotex.Sensor.BinaryArray.start_link(pins: [@obstacle_sensor_left, @obstacle_sensor_right], logic_high: 0)
  def init(:line_sensors), do: Robotex.Sensor.BinaryArray.start_link(pins: [@line_sensor_left, @line_sensor_right])
  def init(:locomotion), do: Robotex.Actuator.DCMotorPair.start_link([forward_pin: @motor_left_forward, reverse_pin: @motor_left_reverse], [forward_pin: @motor_right_forward, reverse_pin: @motor_right_reverse])
  def init(:pan_tilt), do: Robotex.Actuator.PanTilt.start_link([pin: @servo_pan], [pin: @servo_tilt])

  def stop(:sonar, sonar), do: Robotex.Sensor.Sonar.stop(sonar)
  def stop(:obstacle_sensors, sensors), do: Robotex.Sensor.BinaryArray.stop(sensors)
  def stop(:line_sensors, sensors), do: Robotex.Sensor.BinaryArray.stop(sensors)
  def stop(:locomotion, motors), do: Robotex.Actuator.DCMotorPair.stop(motors)
  def stop(:pan_tilt, servos), do: Robotex.Actuator.PanTilt.stop(servos)
end
