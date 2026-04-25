# Godot module system: can_build cannot chain via module-enabled env flags

**Branches:** `feat/module-multiplayer-fabric-asset`, `feat/module-multiplayer-fabric-mmog`
**Status:** Fixed

## Symptom

After adding `can_build` guards that depend on other module-enabled flags
(e.g. `env.get("module_multiplayer_fabric_asset_enabled", False)`),
the module is still compiled. The guard has no effect.

## Root Cause

Godot's SCons module loader initializes **all** `module_X_enabled` flags to
`True` before calling any module's `can_build`. Flags are updated to `False`
as each module's `can_build` is evaluated in alphabetical order.

However, when `multiplayer_fabric_mmog/config.py`'s `can_build` checks
`module_multiplayer_fabric_asset_enabled`, that flag is still `True` (its
initial value), because the flag is not set to `False` until after
`multiplayer_fabric_asset`'s `can_build` runs and updates the environment.

Debug evidence:

```
[mmog can_build] module_multiplayer_fabric_asset_enabled=True  ← always True at this point
```

## Fix

Do **not** chain `can_build` guards via `module_X_enabled` flags. Instead,
replicate the actual conditions directly in every dependent module:

```python
# multiplayer_fabric_mmog/config.py — same condition as the parent module
def can_build(env, platform):
    import os
    return (
        env.get("module_sqlite_enabled", False)
        and env.get("module_http3_enabled", False)
        and os.path.isfile("scene/main/fabric_zone_peer_callbacks.h")
    )
```

`module_sqlite_enabled` and `module_http3_enabled` ARE safe to check because
those modules are alphabetically earlier (h, s) than any `multiplayer_fabric_*`
(m) module, so their flags are correctly set before the multiplayer fabric
modules' `can_build` runs.

## Assembly conflict consequence

All branches that carry the same shared module file (e.g.
`modules/multiplayer_fabric_asset/config.py`) must carry **identical** content.
Divergent versions cause merge conflicts in the git-assembler.

**Rule:** Copy the exact file content from the authoritative branch to every
branch that merges that module. Do not let each branch independently evolve
shared config files.
