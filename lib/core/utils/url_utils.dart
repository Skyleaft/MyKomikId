class UrlUtils {
  static String sanitizeImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    try {
      String decoded = trimmed;
      // Unwrap any potential double/triple encoding
      for (int i = 0; i < 3; i++) {
        if (decoded.contains('%20') || decoded.contains('%25')) {
          final next = Uri.decodeFull(decoded);
          if (next == decoded) break;
          decoded = next;
        } else {
          break;
        }
      }
      return Uri.encodeFull(decoded);
    } catch (_) {
      return Uri.encodeFull(trimmed);
    }
  }
}
