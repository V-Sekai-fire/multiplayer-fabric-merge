# Static checks: ruff-format rejects long CPPPATH lines in SCsub files

**Branches:** `feat/module-multiplayer-fabric`, `feat/module-multiplayer-fabric-mmog`
**Status:** Fixed

## Symptom

Static checks fail in ~44 seconds with:

```
ruff format................................................................Failed
```

The diff shown by the failing hook:

```diff
-env_mf.Prepend(CPPPATH=["#thirdparty/misc/", "#thirdparty/webtransportd/", "#modules/sqlite/thirdparty", "#modules/sqlite"])
```

Exit code 1. All downstream build jobs are skipped.

## Root Cause

`ruff format` enforces an 88-character line limit on Python files, including
SCsub build scripts. When multiple paths were added to a `CPPPATH` list on a
single line to fix the sqlite include path issue (see
`sqlite-cpppath-ordering.md`), the resulting lines exceeded the limit:

- `modules/multiplayer_fabric/SCsub`: 112 chars
- `modules/multiplayer_fabric_mmog/SCsub`: 103 chars

## Fix

Break the list across multiple lines in ruff's preferred style:

```python
env_mf.Prepend(
    CPPPATH=[
        "#thirdparty/misc/",
        "#thirdparty/webtransportd/",
        "#modules/sqlite/thirdparty",
        "#modules/sqlite",
    ]
)
```

**Rule:** Any SCsub `CPPPATH`, `CPPDEFINES`, or similar list with more than
two entries should use the multi-line form to stay within the 88-char limit.

**Commits:**
- `fix: ruff-format SCsub CPPPATH list` (on both branches)
