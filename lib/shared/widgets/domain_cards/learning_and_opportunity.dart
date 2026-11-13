part of '../domain_cards.dart';

/// Portfolio project tile with a tinted preview header (P1).
class ProjectTile extends StatelessWidget {
  const ProjectTile({
    super.key,
    required this.project,
    this.onTap,
    this.heroTag,
  });

  final Project project;
  final VoidCallback? onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final preview = ProjectPreview(project: p, height: 96);
    return SurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heroTag == null ? preview : Hero(tag: heroTag!, child: preview),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(p.title, style: AppText.titleS)),
                    if (p.verified)
                      const StatusBadge(
                        'Mentor-approved',
                        tone: Tone.success,
                        icon: Icons.verified_rounded,
                      )
                    else
                      const StatusBadge('Self-added'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  p.summary,
                  style: AppText.bodyS,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                MonoLabel(
                  p.verified
                      ? 'APPROVED BY ${p.approvedBy} · ${p.approvedOn}'
                      : 'ADDED ${p.addedOn}',
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectPreview extends StatelessWidget {
  const ProjectPreview({
    super.key,
    required this.project,
    this.height = 96,
    this.radius = 0,
  });

  final Project project;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tone = project.tone;
    final base = tone == Tone.neutral ? AppColors.sunken : tone.background;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, Color.lerp(base, AppColors.surface, 0.55)!],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -18,
              child: Icon(
                project.icon,
                size: height * 0.95,
                color:
                    (tone == Tone.neutral
                            ? AppColors.textMuted
                            : tone.foreground)
                        .withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  borderRadius: Radii.rMd,
                ),
                child: Icon(
                  project.icon,
                  size: 20,
                  color: tone == Tone.neutral
                      ? AppColors.textPrimary
                      : tone.foreground,
                ),
              ),
            ),
            if (project.liveUrl.isNotEmpty)
              Positioned(
                left: 14,
                bottom: 12,
                right: 14,
                child: Text(
                  project.liveUrl.replaceFirst('https://', ''),
                  style: AppText.dataMono.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
