defmodule Robotex.CLI do
  def main([script_name | _]) do
    [{module, _} | _] = Code.load_file(script_name)
    Robotex.CLI.run(module)
  end

  def run(module) do
    keyboard = Robotex.KeyboardInput.start([keys: ["q"]])
    script_pid = spawn fn -> apply(module, :run, []) end

    receive do
      {:keyboard_event, _} -> send(script_pid, :robotex_exit)
    end

    Process.exit(keyboard, :kill)
  end
end
