String formatPersonName(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(_capitalizeNamePart)
      .join(' ');
}

String _capitalizeNamePart(String part) {
  return part
      .splitMapJoin(
        RegExp(r"([-'])"),
        onMatch: (match) => match.group(0)!,
        onNonMatch: (segment) {
          if (segment.isEmpty) return segment;
          final lower = segment.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        },
      );
}
