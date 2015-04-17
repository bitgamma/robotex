defmodule Robotex.Algorithm do
  def start_link(algorithm, required_features) do
    parts = for feature <- required_features, into: %{} do
      {feature, Process.whereis(required_features)}
    end
    
    spawn_link(algorithm, :run, [parts])
  end
end
