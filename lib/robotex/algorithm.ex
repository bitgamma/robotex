defmodule Robotex.Algorithm do
  def start_link(algorithm) do
    spawn_link(algorithm, :run, [])
  end
end
