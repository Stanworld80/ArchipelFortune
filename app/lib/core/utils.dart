/// Utilities for robust data parsing, especially for JS/Dart interop on Flutter Web.
class ArchipelUtils {
  /// Safely converts a dynamic value to an integer, providing a fallback.
  /// Handles JSNull, double (from JS numbers), and numeric Strings.
  static int toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? defaultValue;
    }
    return defaultValue;
  }
}
