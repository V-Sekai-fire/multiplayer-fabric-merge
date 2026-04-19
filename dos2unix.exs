#!/usr/bin/env elixir

# Convert CRLF to LF for all files, 4 workers in parallel
{:ok, files} =
  File.ls(".")
  |> then(fn {:ok, _} ->
    paths =
      Path.wildcard("**/*", match_dot: true)
      |> Enum.filter(&File.regular?/1)

    {:ok, paths}
  end)

files
|> Task.async_stream(
  fn path ->
    case System.cmd("dos2unix", [path], stderr_to_stdout: true) do
      {_, 0} -> :ok
      {out, code} -> IO.puts("dos2unix #{path} failed (#{code}): #{out}")
    end
  end,
  max_concurrency: 4,
  ordered: false
)
|> Stream.run()
