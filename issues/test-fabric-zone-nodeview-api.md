# test_fabric_zone: uses removed _hilbert_aoi_band API and old zone_count parameter

**Branch:** `feat/engine-patches` (owns `tests/scene/test_fabric_zone.cpp`)
**Status:** Fixed

## Symptom

macOS build fails with 8 compile errors:

```
tests/scene/test_fabric_zone.cpp:56: error: no member named '_hilbert_aoi_band' in 'FabricZone'
tests/scene/test_fabric_zone.cpp:416: error: reference to type
  'const RelZone::NodeView<MAX_ZONES>' could not bind to an lvalue of type 'int'
```

## Root Cause

`FabricZone::_hilbert_aoi_band(lo, hi, zone_id, zone_count)` was removed from
`fabric_zone.cpp` and replaced by the free function
`RelZone::aoi_band_cells(view, zone_id, aoi_cells, lo, hi)` which takes a
`NodeView` instead of a raw `zone_count` integer.

Similarly, `FabricZone::_collect_migration_intents_s` changed its signature:
the `zone_count` (int) parameter became `const RelZone::NodeView<MAX_ZONES> &`.

The test file was not updated when the API changed.

## Fix

1. Add a `make_uniform_view(int count)` helper to `test_fabric_zone.cpp`
   that constructs a `NodeView` with equal-width zones over `[0, 2^30)`.

2. Replace all `FabricZone::_hilbert_aoi_band(lo, hi, id, count)` calls with:
   ```cpp
   auto view = make_uniform_view(count);
   RelZone::aoi_band_cells(view, (uint32_t)id, FabricZone::AOI_CELLS, lo, hi);
   ```

3. Replace `int zone_count` in `ZoneState` with:
   ```cpp
   RelZone::NodeView<FabricZone::MAX_ZONES> node_view = make_uniform_view(2);
   ```

4. Update all `_collect_migration_intents_s` call sites to pass
   `za.node_view` instead of `za.zone_count`.

**Commit:** `fix: update test_fabric_zone to NodeView API — replace _hilbert_aoi_band and zone_count`
