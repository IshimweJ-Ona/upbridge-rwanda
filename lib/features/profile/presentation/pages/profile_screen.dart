import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/profile/presentation/providers/profile_providers.dart';
import 'package:upbridge/shared/shared.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load your profile.')),
      data: (value) => value == null
          ? const Center(child: Text('Your profile is not available yet.'))
          : PageFrame(
              largeTitle: 'Profile',
              children: [
                SurfaceCard(
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            _initials(value.displayName),
                            tone: Tone.accent,
                            size: 72,
                            imageUrl: value.photoUrl,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(value.displayName, style: AppText.titleL),
                                const SizedBox(height: 4),
                                StatusBadge(
                                  'Youth account',
                                  tone: Tone.success,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderSubtle,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              value.phone.isEmpty
                                  ? 'Phone not added'
                                  : value.phone,
                              style: AppText.bodyS,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SectionLabel('Your profile'),
                ListGroup(
                  children: [
                    ListRow(
                      leading: const IconTile(Icons.edit_outlined),
                      title: 'Edit profile',
                      subtitle: 'Photo, name and phone',
                      onTap: () => context.push('/profile-edit'),
                    ),
                  ],
                ),
                const SectionLabel('Learning'),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconTile(Icons.flag_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Learning goal',
                                  style: AppText.bodySStrong,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  value.learningGoal ?? 'Not selected',
                                  style: AppText.bodyS.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Interests', style: AppText.bodySStrong),
                      const SizedBox(height: 8),
                      value.interests.isEmpty
                          ? Text(
                              'Not selected',
                              style: AppText.bodyS.copyWith(
                                color: AppColors.textMuted,
                              ),
                            )
                          : TagWrap(value.interests, tone: Tone.accent),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SurfaceCard(
                  child: ListRow(
                    leading: const IconTile(
                      Icons.logout_rounded,
                      tone: Tone.danger,
                    ),
                    title: 'Log out',
                    onTap: () => ref.read(authServiceProvider).signOut(),
                  ),
                ),
              ],
            ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.length == 1
      ? parts.first.substring(0, 1).toUpperCase()
      : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
