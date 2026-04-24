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

## Fix

Install a wrapper at `/usr/local/bin/ar` (ahead of `/usr/bin/ar` on PATH)
that redirects the object list through a temporary response file:

```sh
op="$1"; target="$2"; shift 2
tmp=$(mktemp /tmp/ar-rsp.XXXXXX)
printf '%s\n' "$@" > "$tmp"
/usr/bin/ar "$op" "$target" "@$tmp"
rc=$?; rm -f "$tmp"; exit $rc
```

GNU `ar` supports `@file` response files since binutils 2.17.

**Note:** The fix must be cherry-picked to every branch that has
`godot-cpp: true` in its Linux matrix entry. A dedicated branch
`feat/godot-cpp-build` carries the canonical fix; all other affected
branches receive it via cherry-pick.

**Affected branches (cherry-picked):**
`feat/engine-patches`, `feat/module-sqlite`, `feat/module-http3`,
`feat/module-sandbox`, `feat/module-keychain`, `feat/module-lasso`,
`feat/module-openvr`, `feat/module-speech`, `feat/open-telemetry`,
`feat/module-multiplayer-fabric`, `feat/module-multiplayer-fabric-asset`,
`feat/module-multiplayer-fabric-mmog`
