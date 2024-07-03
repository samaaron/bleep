defmodule Mix.Tasks.CopyBleepSynthAssets do
  use Mix.Task

  @shortdoc "Copies assets from assets/vendor/bleep-synth to priv/static/bleep-synth"
  def run(_args) do
    source = Path.join(["assets", "vendor", "bleep-synth", "bleepsynth", "server-assets"])
    destination = Path.join(["priv", "static", "bleep-synth-assets"])

    File.rm_rf!(destination)

    copy_files(source, destination)

    Mix.shell().info("Assets copied from #{source} to #{destination}")
  end

  defp copy_files(source, destination) do
    case File.cp_r(source, destination) do
      {:ok, _} ->
        IO.puts("Files copied successfully from #{source} to #{destination}")

      {:error, reason, file} ->
        IO.puts("Failed to copy #{file}: #{reason}")
    end
  end
end
