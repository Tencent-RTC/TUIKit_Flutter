// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   ListModifyType @ AtomicXCore
// Function: List modification type used by `<ModuleName>.stateChanged`
// passive events.

/// List modification type carried by list-type passive state changes.
///
/// When the engine pushes a list-type state change, the payload carries a
/// [ListModifyType] value to indicate how the local list should be merged.
///
/// | Value | Meaning |
/// |-------|---------|
/// | `none` | No structural change (placeholder) |
/// | `full` | Full replacement — overwrite the local list entirely |
/// | `add` | Incremental add — append new items, deduplicate by key |
/// | `remove` | Incremental remove — filter out items matching the payload keys |
/// | `replace` | Incremental replace — replace items matching the payload keys |
enum ListModifyType {
  /// No structural change (placeholder).
  none(0),

  /// Full replacement — overwrite the local list entirely.
  full(1),

  /// Incremental add — append new items, deduplicate by key.
  add(2),

  /// Incremental remove — filter out items matching the payload keys.
  remove(3),

  /// Incremental replace — replace items matching the payload keys.
  replace(4);

  final int value;
  const ListModifyType(this.value);

  /// Maps a raw integer value to a [ListModifyType].
  ///
  /// Falls back to [ListModifyType.full] when [value] is null or unknown.
  static ListModifyType fromValue(int? value) {
    return ListModifyType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ListModifyType.full,
    );
  }
}
