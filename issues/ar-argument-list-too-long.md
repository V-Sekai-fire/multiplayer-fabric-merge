# godot-cpp build: ar exits with "Argument list too long"

**Branch:** `feat/godot-cpp-build` (fix); cherry-picked to all branches with `godot-cpp: true`
**Status:** Fixed

## Symptom

The `🐧 Linux / Editor w/ Mono` CI job fails after ~35–40 minutes with:

```
scons: *** [godot-cpp/bin/libgodot-cpp.linux.template_debug.dev.x86_64.a]
sh: Argument list too long
Process completed with exit code 2.
```

This only affects the `Linux / Editor w/ Mono` matrix entry because it is the
only one with `godot-cpp: true` in `linux_builds.yml`.

## Root Cause

The `.github/actions/godot-cpp-build/action.yml` step runs:

```sh
scons --directory=./godot-cpp/test ...
```

SCons builds `libgodot-cpp.a` by invoking `ar rc` with every `.o` file as
arguments. On ubuntu-24.04 runners the object count exceeds the kernel
`ARG_MAX` limit, causing the shell to reject the command.

## Failed approach — shell wrapper at `/usr/local/bin/ar`

Installing a shell script wrapper at `/usr/local/bin/ar` does **not** work.
When the shell (`sh`) tries to `execve("/usr/local/bin/ar", [all .o files], env)`,
the kernel returns `E2BIG` before the script ever starts. The wrapper is never
invoked; `sh` reports "Argument list too long" immediately.

## Fix

Add `scu_build=yes` to the SCons invocation. Single Compilation Unit (SCU)
mode merges many `.cpp` files into one before compiling, reducing the number
of `.o` files from ~2000 to ~20. The resulting `ar rc` call is well within
`ARG_MAX`.

```yaml
run: scons --directory=./godot-cpp/test "gdextension_dir=..." ${{ inputs.scons-flags }} scu_build=yes
```

The shell wrapper step was removed entirely.

**Note:** The fix must be cherry-picked to every branch that has
`godot-cpp: true` in its Linux matrix entry.

**Affected branches (cherry-picked):**
`feat/engine-patches`, `feat/module-sqlite`, `feat/module-http3`,
`feat/module-sandbox`, `feat/module-keychain`, `feat/module-lasso`,
`feat/module-openvr`, `feat/module-speech`, `feat/open-telemetry`,
`feat/module-multiplayer-fabric`, `feat/module-multiplayer-fabric-asset`,
`feat/module-multiplayer-fabric-mmog`
