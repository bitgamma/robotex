defmodule Robotex.LineFollower do
  @speed 100

  def run() do
    {:ok, pirocon} = Robotex.Board.Pirocon.start_link
    do_run(pirocon)
  end

  defp do_run(pirocon) do
    react(pirocon)

    receive do
      :robotex_exit -> cleanup(pirocon)
    after 0 ->
      :ok
    end

    do_run(pirocon)
  end

  defp cleanup(pirocon) do
    Robotex.Board.Pirocon.halt(pirocon)
    Robotex.Board.Pirocon.stop(pirocon)
  end

  defp react(pirocon) do
    case Robotex.Board.Pirocon.read_line_sensors(pirocon) do
      {true, true} ->
        Robotex.Board.Pirocon.forward(pirocon, @speed)
      {true, false} ->
        Robotex.Board.Pirocon.spin_left(pirocon, @speed)
      {false, true} ->
        Robotex.Board.Pirocon.spin_right(pirocon, @speed)
      {false, false} ->
        Robotex.Board.Pirocon.spin_right(pirocon, @speed)
    end
  end
end

Robotex.CLI.run(Robotex.LineFollower)
