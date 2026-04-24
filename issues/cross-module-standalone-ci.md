# multiplayer_fabric/asset/mmog: CI fails on standalone branches due to missing dependencies

**Branches:** `feat/module-multiplayer-fabric`, `feat/module-multiplayer-fabric-asset`, `feat/module-multiplayer-fabric-mmog`
**Status:** Fixed (via `can_build` guards)

## Symptom

All build targets fail on these three branches with:

```
fatal error: 'thirdparty/sqlite/sqlite3.h' file not found
fatal error: 'frame.h' file not found        (http3/picoquic header)
```

Exit code 2 on every platform.

## Root Cause

These modules have hard compile-time dependencies on other modules:

| Module | Requires |
|---|---|
| `multiplayer_fabric` | `module_sqlite` (sqlite3.h), `module_http3` (frame.h via picoquic) |
| `multiplayer_fabric_asset` | `multiplayer_fabric` |
| `multiplayer_fabric_mmog` | `multiplayer_fabric_asset` |

When CI runs against the standalone branch (e.g. `feat/module-multiplayer-fabric`),
only that branch's content is present — `module_sqlite` and `module_http3`
don't exist, so their headers are not available.

The gitassembly merges the modules in dependency order, so the assembled
`multiplayer-fabric` branch compiles fine. Only standalone CI is affected.

## Fix

Add `can_build()` guards to each module's `config.py`:

```python
# modules/multiplayer_fabric/config.py
def can_build(env, platform):
    return env.get("module_sqlite_enabled", False) and env.get("module_http3_enabled", False)

# modules/multiplayer_fabric_asset/config.py
def can_build(env, platform):
    return env.get("module_multiplayer_fabric_enabled", False)

# modules/multiplayer_fabric_mmog/config.py
def can_build(env, platform):
    return env.get("module_multiplayer_fabric_asset_enabled", False)
```

When dependencies are absent, Godot's SCons silently skips the module.
Standalone CI passes (nothing to compile = no errors). The assembled
`multiplayer-fabric` branch builds all three because all deps are present.

## Design Note

These modules are only meaningful in the full assembly. Standalone CI
is a lint/smoke check for the module in isolation. Integration CI is
the `multiplayer-fabric` and `multiplayer-fabric-base` assembled branches.
