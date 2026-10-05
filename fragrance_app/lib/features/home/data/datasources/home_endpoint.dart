abstract final class HomeEndpoint {
  static String feed({String? tab, int? page, int? limit}) {
    final Map<String, String> queryParameters = {
      if (tab != null && tab.isNotEmpty) 'tab': tab,
      if (page != null) 'page': page.toString(),
      if (limit != null) 'limit': limit.toString(),
    };

    final uri = Uri(path: '/product/feed', queryParameters: queryParameters);

    return uri.toString();
  }

  static const String featured = '/product/featured';
}
