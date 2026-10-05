abstract final class ProductEndpoint {
  static const String products = '/product';

  static String getOneById(String id) => '/product/:$id';
  static const String getManyByIds = '/product/products/batch';

  // --------------------------------------------------------
  // Brand Screen Features
  static const String brand = '/product/brand';
  static String topSales(int limit) => '/product/top-sales?limit=$limit';
  static String brandProducts(String? name, int? page, int? limit) =>
      '/product/products?name=$name&page=$page&limit=$limit';
  // --------------------------------------------------------

  // --------------------------------------------------------
  // Discovery Screen Features
  static const String moods = '/product/discovery/moods';
  static const String notes = '/product/discovery/notes';
  static const String occasions = '/product/discovery/occasions';
  static const String scentFamilies = '/product/discovery/scent-families';
  static String discoveryFilter({
    String? mood,
    String? note,
    String? occasion,
    String? family,
    String? type,
    int? page,
    int? limit,
  }) {
    final Map<String, String> queryParameters = {
      if (mood != null && mood.isNotEmpty) 'mood': mood,
      if (note != null && note.isNotEmpty) 'note': note,
      if (occasion != null && occasion.isNotEmpty) 'occasion': occasion,
      if (family != null && family.isNotEmpty) 'family': family,
      if (type != null && type.isNotEmpty) 'type': type,
      if (page != null) 'page': page.toString(),
      if (limit != null) 'limit': limit.toString(),
    };

    final uri = Uri(
      path: '/product/discovery/filter',
      queryParameters: queryParameters,
    );

    return uri.toString();
  }
  // --------------------------------------------------------
}
