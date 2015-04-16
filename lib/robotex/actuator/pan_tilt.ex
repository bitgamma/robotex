defmodule Robotex.Actuator.PanTilt do
  defstruct [pan: nil, tilt: nil]

  defmacro is_valid(pan, tilt) do
    quote do
      not (is_nil(unquote(pan)) or is_nil(unquote(tilt)))
    end
  end

  def start_link_servos(pan_opts, tilt_opts) do
    {:ok, pan} = Robotex.Actuator.Servo.start_link(pan_opts)
    {:ok, tilt} = Robotex.Actuator.Servo.start_link(tilt_opts)
    %Robotex.Actuator.PanTilt{pan: pan, tilt: tilt}
  end

  def stop_servos(%Robotex.Actuator.PanTilt{pan: pan, tilt: tilt}) do
    Robotex.Actuator.PanTilt.stop(pan)
    Robotex.Actuator.PanTilt.stop(tilt)
  end

  def pan(%Robotex.Actuator.PanTilt{pan: pan}, degrees) when not is_nil(pan) do
    Robotex.Actuator.Servo.rotate(pan, degrees)
  end

  def tilt(%Robotex.Actuator.PanTilt{tilt: tilt}, degrees) when not is_nil(tilt) do
    Robotex.Actuator.Servo.rotate(tilt, degrees)
  end

  def pan_and_tilt(%Robotex.Actuator.PanTilt{pan: pan, tilt: tilt}, pan_degrees, tilt_degrees) when is_valid(pan, tilt) do
    Robotex.Actuator.Servo.rotate(pan, pan_degrees)
    Robotex.Actuator.Servo.rotate(tilt, tilt_degrees)
  end

  def center(%Robotex.Actuator.PanTilt{pan: pan, tilt: tilt}) when is_valid(pan, tilt) do
    Robotex.Actuator.Servo.rotate(pan, 0)
    Robotex.Actuator.Servo.rotate(tilt, 0)
  end
end
