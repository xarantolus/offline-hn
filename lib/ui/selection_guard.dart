import 'dart:ui';

/// Tracks the one text selection that may be active across many selection
/// areas, so a tap that only dismisses it is not also handled as a tap.
class SelectionGuard {
  Object? _owner;
  VoidCallback? _clear;

  bool get active => _owner != null;

  void changed(Object owner, {required bool selected, VoidCallback? clear}) {
    if (selected) {
      if (_owner != null && _owner != owner) _clear?.call();
      _owner = owner;
      _clear = clear;
    } else if (_owner == owner) {
      _owner = null;
      _clear = null;
    }
  }

  /// Clears the selection and returns true if there was one.
  bool dismiss() {
    final clear = _clear;
    if (_owner == null) return false;
    _owner = null;
    _clear = null;
    clear?.call();
    return true;
  }
}
