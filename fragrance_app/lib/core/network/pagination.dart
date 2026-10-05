final class Pagination {
  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
    required this.hasPrevious,
  });

  final int page;
  final int limit;
  final int total;
  final bool hasNext;
  final bool hasPrevious;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      hasNext: json['hasNext'] as bool,
      hasPrevious: json['hasPrevious'] as bool,
    );
  }
}