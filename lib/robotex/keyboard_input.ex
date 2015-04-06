defmodule Robotex.KeyboardInput do
  def start(opts) do
    spawn(__MODULE__, :run, [Keyword.put(opts, :parent, self)])
  end

  def run(opts) do
    keys = Keyword.fetch!(opts, :keys)
    parent = Keyword.fetch!(opts, :parent)

    case IO.getn("") do
      :eof -> send(parent, {:keyboard_event, :eof})
      {:error, _} -> :error
      key -> send_if_requested(parent, key, keys)
    end

    run(opts)
  end

  defp send_if_requested(parent, key, keys) do
    if Enum.member?(keys, key) do
      send(parent, {:keyboard_event, key})
    end
  end
end
