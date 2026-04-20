# Contributing

Tooling for assembling the multiplayer-fabric Godot fork from upstream
and custom patch sets.  The Elixir script `update_godot_v_sekai.exs`
drives version bumps; `gitassembly/` contains a Go binary that performs
the actual branch merging, cherry-picking, and conflict resolution
strategy.  The result feeds into the `multiplayer-fabric-godot` fork.

## Guiding principles

- **Reproducible assemblies.** Running the assembly script twice
  against the same inputs must produce the same output commit (modulo
  timestamp).  If a step is non-deterministic, fix it before merging.
- **Explicit conflict strategy.** Every merge conflict must be resolved
  by a documented rule (`ours`, `theirs`, custom driver), not by hand.
  Hand-resolved conflicts become invisible to future rebases.
- **Dry-run by default.** All destructive Git operations (force-push,
  branch reset, tag creation) must be gated behind a `--dry-run` flag
  that prints the commands without executing them.
- **Log every decision.** The assembly script emits structured log
  lines for each merge, cherry-pick, and conflict resolution so the
  run is auditable.
- **Error tuples in Elixir, error returns in Go.** Neither the Elixir
  script nor the Go binary should panic or exit non-zero without
  printing a human-readable error message.

## Workflow

```
# Update Godot version
elixir update_godot_v_sekai.exs --version 4.x.y --dry-run

# Build gitassembly
cd gitassembly && go build -o gitassembly . && cd ..

# Run assembly
./gitassembly/gitassembly assemble --config assembly.toml --dry-run
```

## Design notes

### Assembly configuration

`assembly.toml` (or equivalent) describes the ordered list of upstream
refs, custom patch branches, and merge strategies.  The assembly binary
reads this file; no logic is hardcoded in the binary.  Changes to merge
strategy require a config change, not a code change.

### Thirdparty snapshots

`thirdparty/` contains pinned snapshots of upstream tooling used by the
assembly process.  These are not submodules — they are vendored copies
so the tool works offline.  Update a snapshot by replacing the
directory and updating the version comment at the top of the relevant
config file.

### Version derivation

The Elixir script reads the target Godot version from the command line,
not from a hardcoded constant.  The Go binary derives its output branch
name from the version string.  Never hardcode version strings in source
files.
