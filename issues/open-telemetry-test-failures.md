# open_telemetry: two unit test failures on Windows/Linux

**Branch:** `feat/open-telemetry`
**Status:** Fixed

## Symptom

All editor builds (macOS, Windows, Linux) fail at the unit test step with:

```
[doctest] test cases: 1324 | 1322 passed | 2 failed
```

Two specific assertions fail:

```
test_open_telemetry.h(61): ERROR:
  CHECK_FALSE( OTelSpan::is_valid_trace_id("0123456789ABCDEF0123456789abcdef") )
  is NOT correct!

test_open_telemetry.h(201): ERROR:
  CHECK( uuid1.substr(14, 1) == "7" ) is NOT correct!
```

## Root Cause

### Failure 1 — `is_valid_trace_id` accepts uppercase hex

`OTelSpan::is_valid_hex_string` validated:

```cpp
bool is_hex = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
```

The OpenTelemetry specification requires trace IDs to be lowercase hex only.
The test correctly asserts that `"...ABCDEF..."` is invalid, but the
implementation accepted it.

### Failure 2 — `generate_uuid_v7` hex encoding

`generate_uuid_v7` used `String::num_int64(..., 16, false).pad_zeros(2)` to
convert each byte to a 2-character hex string. On some platforms or Godot
build configurations this produced unexpected results for the version nibble,
causing position 14 of the UUID string (the version digit) to not be `"7"`.

## Fix

**Failure 1:** Remove the uppercase range from `is_valid_hex_string`:
```cpp
bool is_hex = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f');
```

**Failure 2:** Replace the `num_int64`/`pad_zeros` approach with explicit
nibble indexing, which is unambiguous on all platforms:
```cpp
static const char hex_chars[] = "0123456789abcdef";
hex += hex_chars[b >> 4];
hex += hex_chars[b & 0x0F];
```

**Commit:** `fix: open_telemetry — reject uppercase hex in trace IDs, use nibble table for UUID v7 hex`
