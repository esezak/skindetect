// Common utility functions used across the app

/// Cleans a raw disease key by removing numeric prefixes, replacing underscores
/// with spaces, collapsing whitespace, and capitalizing each word.
/// Examples:
/// - "1_Melanoma" -> "Melanoma"
/// - "Unknown_Normal" -> "Unknown Normal"
/// - "__a__b__" -> "A B"
String cleanKey(String raw) {
  // Remove leading numeric prefix like "1_"
  String s = raw.replaceAll(RegExp(r'^[0-9]+_'), '');
  // Replace underscores with spaces, collapse multiple spaces, and trim
  s = s.replaceAll('_', ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  if (s.isEmpty) return '';

  final parts = s.split(' ').where((w) => w.isNotEmpty);
  return parts
      .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
      .join(' ');
}
