import '../../product/data/model/product_model.dart';

/// One customer's star rating and comment on a perfume.
final class ReviewModel {
  final String id;
  final String productId;
  final int rating;
  final String comment;
  final String userName;
  final String? userPhoto;
  final bool isMine;
  final DateTime updatedAt;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.userPhoto,
    required this.isMine,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'].toString(),
    productId: json['productId'].toString(),
    rating: (json['rating'] as num? ?? 0).toInt(),
    comment: json['comment'] as String? ?? '',
    userName: json['userName'] as String? ?? 'Customer',
    userPhoto: json['userPhoto'] as String?,
    isMine: json['isMine'] == true,
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );

  /// "3 Oct 2026"
  String get dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${updatedAt.day} ${months[updatedAt.month - 1]} ${updatedAt.year}';
  }
}

/// Everything the product page shows about its reviews.
final class ReviewSummary {
  final double average;
  final int count;

  /// Stars (5..1) to how many reviews gave that many.
  final Map<int, int> breakdown;
  final ReviewModel? myReview;

  /// True when the signed-in customer bought this perfume.
  final bool canReview;
  final List<ReviewModel> reviews;
  final bool hasMore;

  const ReviewSummary({
    required this.average,
    required this.count,
    required this.breakdown,
    required this.myReview,
    required this.canReview,
    required this.reviews,
    required this.hasMore,
  });

  factory ReviewSummary.fromBody(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final rawBreakdown = data['breakdown'];
    final rawReviews = data['reviews'];
    final rawMine = data['myReview'];
    final pagination = body['pagination'];
    return ReviewSummary(
      average: (data['average'] as num? ?? 0).toDouble(),
      count: (data['count'] as num? ?? 0).toInt(),
      breakdown: {
        for (var stars = 5; stars >= 1; stars--)
          stars: rawBreakdown is Map
              ? ((rawBreakdown['$stars'] as num?) ?? 0).toInt()
              : 0,
      },
      myReview: rawMine is Map<String, dynamic>
          ? ReviewModel.fromJson(rawMine)
          : null,
      canReview: data['canReview'] == true,
      reviews: [
        if (rawReviews is List)
          for (final item in rawReviews)
            ReviewModel.fromJson(item as Map<String, dynamic>),
      ],
      hasMore: pagination is Map && pagination['hasNext'] == true,
    );
  }
}

/// A perfume the customer bought, with their review if they wrote one.
typedef PurchasedReview = ({ProductModel product, ReviewModel? review});
