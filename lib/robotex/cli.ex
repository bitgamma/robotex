defmodule Robotex.CLI do
  def main(argv) do
    script_name = hd(argv)

    keyboard = Robotex.KeyboardInput.start([keys: ["q"]])
    [{module, _} | _] = Code.load_file(script_name)

    main_pid = self

    script_pid = spawn fn ->
      cleanup_data = apply(module, :init, [])
      send main_pid, {:script_cleanup_data, cleanup_data}
      apply(module, :run, cleanup_data)
    end

    script_cleanup_data = receive do
      {:script_cleanup_data, cleanup_data} -> cleanup_data
    end

    receive do
      {:keyboard_event, _} -> Process.kill(script_pid, :exit)
    end

    apply(module, :cleanup, script_cleanup_data)
    Process.kill(keyboard, :exit)
  end
end
