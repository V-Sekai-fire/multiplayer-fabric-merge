# sandbox: Win32 libriscv files incorrectly removed

**Branch:** `feat/module-sandbox`
**Status:** Fixed

## Symptom

macOS and Windows builds fail with:

```
fatal error: '../win32/epoll.cpp' file not found
fatal error: 'win32/dlfcn.h': No such file or directory
```

## Root Cause

A commit "Remove tracked Win32 libriscv files — match .gitignore
`[Ww][Ii][Nn]32/` pattern" ran `git rm` on all files matching the
gitignore pattern, including the Win32 compatibility shims inside
`modules/sandbox/thirdparty/libriscv/lib/libriscv/win32/`.

These files are not build artifacts. They are source files used by
`linux/system_calls.cpp` and `tr_translate.cpp` for cross-platform
epoll and `dlfcn` emulation on macOS and Windows.

Seven files were incorrectly deleted:
- `win32/dlfcn.cpp`, `win32/dlfcn.h`
- `win32/epoll.cpp`
- `win32/rsp_server.hpp`
- `win32/system_calls.cpp`
- `win32/tr_msvc.cpp`
- `win32/ws2.hpp`

## Fix

1. Restore the seven files from the commit before the deletion.
2. Add a `.gitignore` negation to prevent future accidents:
   ```
   [Ww][Ii][Nn]32/
   !modules/sandbox/thirdparty/libriscv/lib/libriscv/win32/
   ```

**Commits:**
- `fix: restore libriscv win32 files and exempt from gitignore`
