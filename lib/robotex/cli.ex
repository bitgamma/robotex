defmodule Robotex.CLI do
  def main(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [robot: :string, algorithm: :string], aliases: [r: :robot, a: :algorithm])

    robot_spec = Keyword.fetch!(opts, :robot)
    algo_spec = Keyword.fetch!(opts, :algorithm)

    robot = load_module(robot_spec, "Robotex.Robot")
    algorithm = load_module(algo_spec, "Robotex.Algorithm")

    Robotex.Supervisor.start_link(robot, algorithm)
  end

  defp load_module(spec, module_prefix), do:  do_load_module(File.regular?(spec), spec, module_prefix)

  defp do_load_module(true, path, _module_prefix) do
    [{module, _} | _] = Code.load_file(path)
    module
  end
  defp do_load_module(false, module_name, module_prefix) do
    module = String.to_atom("Elixir.#{module_name}")

    if Code.ensure_loaded?(module) do
      module
    else
      # fail if the module does not exist, but the error message will not be clear
      String.to_existing_atom("Elixir.#{module_prefix}.#{module_name}")
    end
  end
end
