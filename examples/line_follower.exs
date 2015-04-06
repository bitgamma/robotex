defmodule Robotex.LineFollower do
  @speed 100

  def run(pirocon, keyboard, :stop, _) do
    Robotex.Board.Pirocon.halt(pirocon)
    Robotex.Board.Pirocon.stop(pirocon)
    Process.exit(keyboard, :kill)
  end
  def run(pirocon, keyboard, state, {left, right}) do
    state = react(pirocon, {state, left, right})
    get_next(pirocon, keyboard, state)
  end

  def get_next(pirocon, keyboard, :go) do
    receive do
      {:keyboard_event, _} -> run(pirocon, keyboard, :stop, nil)
      {:robotex_line_change, _, left, right} -> run(pirocon, keyboard, :go, {left, right})
    end
  end
  def get_next(pirocon, keyboard, :spin) do
    receive do
      {:keyboard_event, _} -> run(pirocon, keyboard, :stop, nil)
      {:robotex_line_change, _, left, right} -> run(pirocon, keyboard, :spin, {left, right})
    after 1000 ->
      run(pirocon, keyboard, :spin, {false, false})
    end
  end

  def react(pirocon, state) do
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

{:ok, pirocon} = Robotex.Board.Pirocon.start_link
keyboard = Robotex.KeyboardInput.start([keys: ["q"]])

Robotex.Board.Pirocon.set_notify_on_line_change(pirocon, true)
Robotex.LineFollower.run(pirocon, keyboard, :go, Robotex.Board.Pirocon.read_line_sensors(pirocon))
