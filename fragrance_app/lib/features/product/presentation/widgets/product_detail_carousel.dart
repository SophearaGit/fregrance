import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/core.dart';

class ProductDetailCarousel extends StatefulWidget {
  final List<String> images;
  final int defaultImageIndex;

  const new({super.key, required this.images, required this.defaultImageIndex});

  @override
  State<ProductDetailCarousel> createState() => _ProductDetailCarouselState();
}

class _ProductDetailCarouselState extends State<ProductDetailCarousel> {
  late int _activeImageIndex;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _activeImageIndex = widget.defaultImageIndex;
    if (_activeImageIndex >= widget.images.length || _activeImageIndex < 0) {
      _activeImageIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final images = widget.images;

    if (images.isEmpty) {
      return Container(
        height: 320,
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: images.length,
          options: CarouselOptions(
            height: 340,
            viewportFraction: 1.0,
            initialPage: _activeImageIndex,
            enableInfiniteScroll: images.length > 1,
            onPageChanged: (index, reason) {
              setState(() {
                _activeImageIndex = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final imageUrl = images.displayImage(index);
            return Container(
              width: double.infinity,
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              child: Image.network(
                imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          AnimatedSmoothIndicator(
            activeIndex: _activeImageIndex,
            count: images.length,
            onDotClicked: (index) async =>
                await _carouselController.animateToPage(index),
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
              activeDotColor: colorScheme.primary,
              dotColor: colorScheme.outlineVariant.withAlpha(150),
            ),
          ),
        ],
      ],
    );
  }
}
