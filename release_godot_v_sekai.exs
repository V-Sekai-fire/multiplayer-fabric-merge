#!/usr/bin/env elixir

version =
  "config.sh"
  |> File.read!()
  |> String.split("\n")
  |> Enum.find_value(fn line ->
    case Regex.run(~r/^VERSION=(.+)$/, String.trim(line)) do
      [_, v] -> String.trim(v)
      _ -> nil
    end
  end) || raise "VERSION not found in config.sh"

original_branch = "main"
merge_remote = "v-sekai-godot"
merge_branch = "groups-#{version}"

argv = System.argv()

if Enum.any?(argv, &(&1 in ["-h", "--help"])) do
  IO.puts("""
  Usage: elixir #{__ENV__.file} [--help|-h] [--dry-run|--no-push|-n]

  Compiles all branches in gitassembly and pushes to V-Sekai/godot.
  Automatically creates a timestamp tag and pushes by default.

  --help, -h       Display help
  --dry-run, -n    Do not push or create tag.
  """)
  System.halt(0)
end

dry_run = Enum.any?(argv, &(&1 in ["-n", "--no-push", "--dry-run"]))

run! = fn cmd, args ->
  case System.cmd(cmd, args, stderr_to_stdout: true) do
    {output, 0} ->
      if output != "", do: IO.puts(output)
      output
    {output, code} ->
      IO.puts(output)
      raise "Command failed (exit #{code}): #{cmd} #{Enum.join(args, " ")}"
  end
end

add_remote = fn name, url ->
  System.cmd("git", ["remote", "add", name, url], stderr_to_stdout: true)
  System.cmd("git", ["remote", "set-url", name, url], stderr_to_stdout: true)
  run!.("git", ["fetch", name])
end

IO.puts("Checkout remotes")
add_remote.("v-sekai-godot", "https://github.com/V-Sekai/godot.git")

current_branch = String.trim(run!.("git", ["rev-parse", "--abbrev-ref", "HEAD"]))
if current_branch != original_branch do
  IO.puts("Failed to run merge script: not on #{original_branch} branch.")
  System.halt(1)
end

IO.puts("*** Working on assembling gitassembly")

has_changes =
  case System.cmd("git", ["diff", "--quiet", "HEAD"], stderr_to_stdout: true) do
    {_, 0} -> false
    _ -> true
  end

run!.("git", ["stash"])

run!.("git", ["checkout", original_branch, "--force"])
System.cmd("git", ["branch", "-D", merge_branch], stderr_to_stdout: true)
run!.("python3", ["./thirdparty/git-assembler", "-av", "--recreate", "--config", "gitassembly"])
run!.("git", ["checkout", merge_branch, "-f"])

merge_date = DateTime.utc_now() |> DateTime.to_iso8601()
merge_tag = "#{merge_branch}.#{merge_date}" |> String.replace(":", "") |> String.replace(" ", "")

run!.("git", ["commit", "--allow-empty", "-m", "Merge branch '#{merge_branch}' into '#{original_branch}' [skip ci]"])

if not dry_run do
  run!.("git", ["tag", "-a", merge_tag, "-m", "Committed at #{merge_date}."])
  run!.("git", ["push", merge_remote, merge_tag])
  run!.("git", ["push", merge_remote, merge_branch, "-f"])
  run!.("git", ["checkout", original_branch, "--force"])
  System.cmd("git", ["branch", "-D", merge_branch], stderr_to_stdout: true)
else
  run!.("git", ["checkout", original_branch, "--force"])
  IO.puts("#{merge_branch} was created and is ready to push.")
end

IO.puts("ALL DONE. ----------------------------")

if has_changes do
  IO.puts("""
  Note that uncommitted changes may have been stashed. Run
      git stash apply
  to re-apply them.
  """)
  run!.("git", ["stash", "list"])
end
