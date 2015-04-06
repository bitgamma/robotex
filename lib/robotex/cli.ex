defmodule Robotex.CLI do
  def main([script_name | _]) do
    keyboard = Robotex.KeyboardInput.start([keys: ["q"]])
    [{module, _} | _] = Code.load_file(script_name)
    script_pid = spawn fn -> apply(module, :run, []) end

    receive do
      {:keyboard_event, _} -> send(script_pid, :robotex_exit)
    end

    Process.exit(keyboard, :kill)
  end
end
