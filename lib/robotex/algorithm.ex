defmodule Robotex.Algorithm do
  def start_link(algorithm) do
    {:ok, spawn_link(algorithm, :run, [])}
  end
end
