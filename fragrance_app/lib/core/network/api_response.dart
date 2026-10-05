final class ApiResponse<T> {
  final String message;
  final T data;

  const ApiResponse({required this.message, required this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse(
      message: json['message'] as String,
      data: fromJsonT(json['data']),
    );
  }
}

final class ApiPaginationResponse<T> {
  final String message;
  final T data;
  final ApiPagination pagination;

  const ApiPaginationResponse({
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory ApiPaginationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final paginationMap = json['pagination'] is Map<String, dynamic>
        ? json['pagination'] as Map<String, dynamic>
        : <String, dynamic>{
            'page': 1,
            'limit': 10,
            'total': 0,
            'hasNext': false,
            'hasPrevious': false,
          };

    return ApiPaginationResponse(
      message: json['message'] as String? ?? '',
      data: fromJsonT(json['data']),
      pagination: ApiPagination.fromJson(paginationMap),
    );
  }
}

final class ApiPagination {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;
  final bool hasPrevious;

  const ApiPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory ApiPagination.fromJson(Map<String, dynamic> json) {
    return ApiPagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      hasNext: json['hasNext'] as bool,
      hasPrevious: json['hasPrevious'] as bool,
    );
  }
}
