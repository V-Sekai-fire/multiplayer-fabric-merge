# Contributing

Tooling for assembling the multiplayer-fabric Godot fork from upstream
and custom patch sets.  The Elixir script `update_godot_v_sekai.exs`
drives version bumps; `thirdparty/git-assembler` is a Python 3 script
that performs the actual branch merging, cherry-picking, and conflict
resolution strategy; `gitassembly` is the configuration file that
describes what to merge.  The result feeds into the
`multiplayer-fabric-godot` fork.

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
- **Error tuples in Elixir, exit codes in Python.** Neither the Elixir
  script nor the Python assembler should exit non-zero without printing
  a human-readable error message.

## Workflow

```
# Update Godot version (dry run)
elixir update_godot_v_sekai.exs --dry-run

# Run assembly directly
python3 ./thirdparty/git-assembler -av --recreate --config gitassembly
```

## Design notes

### Assembly configuration

`gitassembly` describes the ordered list of upstream refs, custom patch
branches, and merge strategies in a simple line-oriented format:

```
stage <target-branch> <base-ref>   # reset target to base
merge <target-branch> <source-ref> # merge source into target
```

No logic is hardcoded in the assembler.  Changes to merge strategy
require a config change, not a code change.

### Thirdparty snapshots

`thirdparty/` contains pinned snapshots of upstream tooling used by the
assembly process.  These are not submodules — they are vendored copies
so the tool works offline.  Update a snapshot by replacing the
directory and updating the version comment at the top of the relevant
config file.

### Version derivation

The Elixir script reads the target Godot version from `.env` (`VERSION`)
and the command line, not from a hardcoded constant.  Never hardcode
version strings in source files.
