defmodule Robotex.LineFollower do
  @speed 100

  def init() do
    {:ok, pirocon} = Robotex.Board.Pirocon.start_link

    Robotex.Board.Pirocon.set_notify_on_line_change(pirocon, true)
    {pirocon, :go, Robotex.Board.Pirocon.read_line_sensors(pirocon)}
  end

  def run({pirocon, state, {left, right}}) do
    state = react(pirocon, {state, left, right})

    receive do
      {:robotex_line_change, _, new_left, new_right} -> run({pirocon, state, {new_left, new_right}})
    after 1000 ->
      run({pirocon, state, {left, right}})
    end
  end

  def cleanup({pirocon, _, _}) do
    Robotex.Board.Pirocon.halt(pirocon)
    Robotex.Board.Pirocon.stop(pirocon)
  end

  defp react(pirocon, state) do
    case state do
      {_, true, true} ->
        Robotex.Board.Pirocon.forward(pirocon, @speed)
        :go
      {_, true, false} ->
        Robotex.Board.Pirocon.spin_left(pirocon, @speed)
        :go
      {_, false, true} ->
        Robotex.Board.Pirocon.spin_right(pirocon, @speed)
        :go
      {:go, false, false} ->
        Robotex.Board.Pirocon.spin_right(pirocon, @speed)
        :spin
      {:spin, false, false} ->
        Robotex.Board.Pirocon.spin_left(pirocon, @speed)
        :go
    end
  end
end
