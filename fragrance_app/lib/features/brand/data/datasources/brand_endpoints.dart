abstract final class BrandEndpoints {
  static const String brand = '/product/brand';

  static String brandProducts({String? name, String? page, String? limit}) {
    final Map<String, dynamic> queryParameters = {
      'name': name,
      'page': page,
      'limit': limit,
    };

    final uri = Uri(
      path: '/product/brand/products',
      queryParameters: queryParameters,
    );

    return uri.toString();
  }
}
