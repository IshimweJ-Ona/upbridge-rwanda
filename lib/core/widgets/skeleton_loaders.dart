import 'package:flutter/material.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_tokens.dart';
import 'package:upbridge/shared/animations/shimmer.dart';

class SkeletonCardLoader extends StatelessWidget {
  const SkeletonCardLoader({super.key, this.lines = 2});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.s3),
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.rLg,
        border: Border.all(color: p.borderSubtle),
      ),
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                SkeletonBox(width: 44, height: 44, radius: Radii.md),
                SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 170, height: 14),
                      SizedBox(height: Space.s2),
                      SkeletonBox(width: 110, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            for (var i = 0; i < lines; i++) ...[
              const SizedBox(height: Space.s3),
              SkeletonBox(width: i.isEven ? double.infinity : 200, height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class SkeletonDashboardLoader extends StatelessWidget {
  const SkeletonDashboardLoader({super.key, this.cards = 3});

  final int cards;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonMetricsGridLoader(),
          const SizedBox(height: Space.s4),
          for (var i = 0; i < cards; i++) const SkeletonCardLoader(lines: 2),
        ],
      ),
    );
  }
}

class SkeletonMetricsGridLoader extends StatelessWidget {
  const SkeletonMetricsGridLoader({super.key, this.tiles = 4});

  final int tiles;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Shimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: Space.s3,
          mainAxisSpacing: Space.s3,
          mainAxisExtent: 86,
        ),
        itemCount: tiles,
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(Space.s3),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: Radii.rLg,
            border: Border.all(color: p.borderSubtle),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 44, height: 22),
              SkeletonBox(width: 96, height: 11),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonListLoader extends StatelessWidget {
  const SkeletonListLoader({super.key, this.rows = 4, this.showAvatar = true});

  final int rows;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows; i++)
            Container(
              margin: const EdgeInsets.only(bottom: Space.s3),
              padding: const EdgeInsets.all(Space.s4),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: Radii.rLg,
                border: Border.all(color: p.borderSubtle),
              ),
              child: Shimmer(
                child: Row(
                  children: [
                    if (showAvatar) ...[
                      const SkeletonBox(
                        width: 40,
                        height: 40,
                        radius: Radii.md,
                      ),
                      const SizedBox(width: Space.s3),
                    ],
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 180, height: 14),
                          SizedBox(height: Space.s2),
                          SkeletonBox(width: 130, height: 11),
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.s2),
                    const SkeletonBox(width: 64, height: 24, radius: Radii.xl),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SkeletonDetailPageLoader extends StatelessWidget {
  const SkeletonDetailPageLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonCardLoader(lines: 3),
          SkeletonCardLoader(lines: 2),
          SkeletonListLoader(rows: 2, showAvatar: false),
        ],
      ),
    );
  }
}
