extension ImageListX on List<String> {
  /// Safely gets the image at [preferredIndex], falling back to
  /// the first element or null if out of bounds.
  String? displayImage([int? preferredIndex]) {
    if (isEmpty) return null;

    final index = preferredIndex ?? 0;
    if (index >= 0 && index < length) {
      return this[index];
    }
    return first;
  }
}
