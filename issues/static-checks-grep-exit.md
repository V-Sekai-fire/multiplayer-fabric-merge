# Static checks: grep -v exits 1 on empty changed-files list

**Branch:** `feat/engine-patches` (owns `.github/workflows/static_checks.yml`)
**Status:** Fixed

## Symptom

CI run for any branch with no changed source files fails in the
"Write changed file list to response file" step with exit code 1.
The job completes in ~40 seconds before any build jobs start.

## Root Cause

```yaml
echo '${{ steps.changed-files.outputs.everything_all_changed_files }}' \
  | tr '" "' '\n' | sed 's/^"//;s/"$//' | grep -v '^$' \
  > /tmp/changed_files.txt
```

When the changed-files output is empty (e.g. a merge commit or a commit
that only touches non-source files), `grep -v '^$'` finds no matching
lines and exits with code 1. Under `bash -e` this terminates the step.

## Fix

Wrap `grep` in a subshell with `|| true` so an empty match is not fatal:

```yaml
| { grep -v '^$' || true; } \
```

**Commit:** `fix: static_checks grep -v exit 1 on empty changed-files list`
