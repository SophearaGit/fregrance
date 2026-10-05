abstract final class DiscoveryEndpoints {
  static const String moods = '/product/discovery/moods';

  static const String notes = '/product/discovery/notes';

  static const String occasions = '/product/discovery/occasions';

  static const String scentFamilies = '/product/discovery/scent-families';

  static String filter({
    String? mood,
    String? note,
    String? occasion,
    String? family,
    String? type,
    int? page,
    int? limit,
  }) {
    final queryParams = <String, String>{};

    if (mood != null && mood.isNotEmpty) queryParams['mood'] = mood;
    if (note != null && note.isNotEmpty) queryParams['note'] = note;
    if (occasion != null && occasion.isNotEmpty) {
      queryParams['occasion'] = occasion;
    }
    if (family != null && family.isNotEmpty) queryParams['family'] = family;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();

    if (queryParams.isEmpty) return '/product/discovery/filter';

    final query = queryParams.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '/product/discovery/filter?$query';
  }
}
