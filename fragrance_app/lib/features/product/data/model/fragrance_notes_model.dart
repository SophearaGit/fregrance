final class FragranceNotesModel {
  final List<String> top;
  final List<String> middle;
  final List<String> base;

  const FragranceNotesModel({
    required this.top,
    required this.middle,
    required this.base,
  });

  factory FragranceNotesModel.fromJson(Map<String, dynamic> json) {
    return FragranceNotesModel(
      top: json['top'] is List
          ? (json['top'] as List).map((e) => e.toString()).toList()
          : const [],
      middle: json['middle'] is List
          ? (json['middle'] as List).map((e) => e.toString()).toList()
          : const [],
      base: json['base'] is List
          ? (json['base'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  // Helper to retrieve notes by category name
  List<String> getNotesByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'top':
        return top;
      case 'middle':
        return middle;
      case 'base':
        return base;
      default:
        return [];
    }
  }
}
