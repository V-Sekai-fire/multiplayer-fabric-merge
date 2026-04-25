# sqlite module duplicated in dependent branches with stale SCsub

**Branches:** `feat/module-multiplayer-fabric`, `feat/module-multiplayer-fabric-asset`, `feat/module-multiplayer-fabric-mmog`
**Status:** Fixed

## Symptom

`gscons` fails with linker errors (`Undefined symbols: _spmemvfs_close_db, ...`)
or header-not-found errors even after the `feat/module-sqlite` SCsub was fixed,
because the dependent branches carry their own stale copy of `modules/sqlite/SCsub`.

## Root Cause

`feat/module-multiplayer-fabric` was created by merging `feat/module-sqlite`
into an earlier state and then advancing independently. The `modules/sqlite/SCsub`
in these branches still contained the original broken path:

```python
env.Append(CPPPATH=["#thirdparty"])
env_thirdparty.add_source_files(..., "#thirdparty/sqlite/sqlite3.c")
env_thirdparty.add_source_files(..., "#thirdparty/spmemvfs/spmemvfs.c")
```

Fixing `feat/module-sqlite` does not retroactively fix the copies in the
three dependent branches.

## Fix

Apply the corrected `modules/sqlite/SCsub` directly to each affected branch:

```python
env.Append(CPPPATH=["#modules/sqlite/thirdparty", "#modules/sqlite"])
env_thirdparty.add_source_files(..., "#modules/sqlite/thirdparty/sqlite/sqlite3.c")
env_thirdparty.add_source_files(..., "#modules/sqlite/thirdparty/spmemvfs/spmemvfs.c")
```

**Rule:** When a shared module (sqlite) is fixed, check all branches that carry
a merged copy of that module and apply the fix there too.
