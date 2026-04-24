# openvr: CODEOWNERS entry missing + hook script not executable

**Branch:** `feat/module-openvr`
**Status:** Fixed

## Symptom

Static checks fail in under 2 minutes with two pre-commit errors:

1. `validate-codeowners` hook:
   ```
   ERROR: modules/openvr/hooks/pre-commit-clang-format: <UNOWNED>
   ```

2. `check-shebang-scripts-are-executable` hook:
   ```
   modules/openvr/hooks/pre-commit-clang-format: has a shebang but is not marked executable!
   ```

Both failures block all downstream build jobs.

## Root Cause

The `modules/openvr/` directory was added to the repository without:
1. An entry in `.github/CODEOWNERS` — every tracked file must have an owner.
2. The executable bit set on `hooks/pre-commit-clang-format`, which contains
   a `#!/bin/bash` shebang.

## Fix

1. Add CODEOWNERS entry under the XR section (consistent with other XR modules):
   ```
   /modules/openvr/  @fire
   ```

2. Set the executable bit:
   ```sh
   git add --chmod=+x modules/openvr/hooks/pre-commit-clang-format
   ```

**Commits:**
- `fix: mark modules/openvr/hooks/pre-commit-clang-format as executable`
- `fix: add modules/openvr/ to CODEOWNERS`
