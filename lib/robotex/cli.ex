defmodule Robotex.CLI do
  def main(argv) do
    script_name = hd(argv)
    Code.load_file(script_name)
  end
end
