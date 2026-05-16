/// Normalizes outgoing request JSON produced by DTO `toJson()` methods.
///
/// The backend uses Rust/serde DTOs. For many optional collection fields the
/// server accepts an omitted field and applies `#[serde(default)]`, but rejects
/// an explicit JSON `null` because the Rust type is `Vec<T>` rather than
/// `Option<Vec<T>>`.
///
/// This class removes `null` object properties recursively before a payload is
/// sent through Dio. Existing empty arrays/objects are preserved, so callers can
/// still intentionally clear list-like settings by passing `[]`.
class JsonPayloadNormalizer {
  const JsonPayloadNormalizer._();

  static Object? normalize(Object? value) {
    if (value is Map) {
      final normalized = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final child = normalize(entry.value);
        if (child == null) {
          // Omit null properties. This prevents payloads such as:
          // { "can_see": null } for server-side Vec<T> fields.
          continue;
        }
        normalized[key] = child;
      }
      return normalized;
    }

    if (value is Iterable) {
      return value.map(normalize).toList(growable: false);
    }

    return value;
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> value) {
    final normalized = normalize(value);
    if (normalized is Map<String, dynamic>) return normalized;
    return const <String, dynamic>{};
  }
}
