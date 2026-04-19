#!/usr/bin/env elixir

File.mkdir_p!("thirdparty")

url = "https://gitlab.com/wavexx/git-assembler/-/raw/master/git-assembler"
dest = "./thirdparty/git-assembler"

IO.puts("Downloading git-assembler...")
{_, 0} = System.cmd("curl", ["-L", url, "-o", dest], into: IO.stream())

File.chmod!(dest, 0o755)

# RERERE is not allowed: merge state cached on dev machines breaks CI/CD
{_, 0} = System.cmd("git", ["config", "rerere.enabled", "false"], into: IO.stream())

IO.puts("Done.")
