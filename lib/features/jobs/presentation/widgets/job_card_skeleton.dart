import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Placeholder card shown while job list is loading.
/// Matches the visual height of a real JobCard.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _Box(height: 16, width: double.infinity)),
                  const SizedBox(width: 12),
                  _Box(height: 16, width: 60),
                ],
              ),
              const SizedBox(height: 10),
              _Box(height: 12, width: 140),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Box(height: 12, width: 80),
                  const SizedBox(width: 16),
                  _Box(height: 12, width: 100),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Box(height: 24, width: 60, radius: 12),
                  const SizedBox(width: 8),
                  _Box(height: 24, width: 50, radius: 12),
                  const SizedBox(width: 8),
                  _Box(height: 24, width: 70, radius: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.height, required this.width, this.radius = 6});

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
