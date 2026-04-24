# sqlite: include path not visible to modules that load earlier alphabetically

**Branches:** `feat/module-sqlite`, `feat/module-multiplayer-fabric`, `feat/module-multiplayer-fabric-mmog`
**Status:** Fixed

## Symptom

Any build that includes both `module_sqlite_enabled=yes` and the
`multiplayer_fabric` module fails with:

```
fatal error: 'thirdparty/sqlite/sqlite3.h' file not found
```

in `modules/multiplayer_fabric/fabric_zone_journal.h`.

## Root Cause

### Part 1 — wrong path in sqlite SCsub

When the sqlite module was moved from the root `thirdparty/sqlite/` to
`modules/sqlite/thirdparty/sqlite/`, the SCsub was updated to:

```python
env.Append(CPPPATH=["#modules/sqlite/thirdparty"])
```

Code that does `#include <thirdparty/sqlite/sqlite3.h>` requires the
parent directory `#modules/sqlite` in CPPPATH, not the child. With only
`#modules/sqlite/thirdparty`, the compiler looks for
`modules/sqlite/thirdparty/thirdparty/sqlite/sqlite3.h` — which does
not exist.

### Part 2 — SCons module loading order

Even after adding `#modules/sqlite` to `sqlite/SCsub`, the
`multiplayer_fabric` module still failed. SCons reads all `SConscript`
files in order before building. Modules are loaded alphabetically:
`multiplayer_fabric` (m) loads before `sqlite` (s). Each module clones
`env_modules` at read time. Changes that `sqlite/SCsub` makes to the
environment after the clone are not visible in the already-registered
`multiplayer_fabric` build nodes.

## Fix

Each module that includes sqlite headers must declare the include path
in its own SCsub, not rely on sqlite's SCsub to propagate it:

**`modules/sqlite/SCsub`:**
```python
env.Append(CPPPATH=["#modules/sqlite/thirdparty", "#modules/sqlite"])
```

**`modules/multiplayer_fabric/SCsub`:**
```python
env_mf.Prepend(CPPPATH=[..., "#modules/sqlite/thirdparty", "#modules/sqlite"])
```

**`modules/multiplayer_fabric_mmog/SCsub`:**
```python
env_mmog.Prepend(CPPPATH=["#modules/sqlite/thirdparty", "#modules/sqlite", "#modules/multiplayer_fabric"])
```

**Lesson:** Never rely on another module's SCsub to expose include paths.
Every module that uses another module's headers must add those paths itself,
because module load order is alphabetical and not guaranteed.
