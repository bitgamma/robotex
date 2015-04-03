defmodule Robotex.Util do
  def usleep(usec) do
    start = :erlang.now
    do_usleep(start, usec)
  end

  defp do_usleep(start, usec) do
    if :timer.now_diff(:erlang.now, start) > usec do
      :ok
    else
      do_usleep(start, usec)
    end
  end
end
