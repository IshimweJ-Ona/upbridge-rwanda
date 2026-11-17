import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/profile/presentation/providers/profile_providers.dart';
import 'package:upbridge/features/profile/domain/entities/profile.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';
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
              eyebrow: value.phone,
              children: [
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            _initials(value.displayName),
                            tone: Tone.accent,
                            size: 56,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              value.displayName,
                              style: AppText.titleM,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(value.emailSafeLabel, style: AppText.bodyS),
                    ],
                  ),
                ),
                const SectionLabel('Your profile'),
                ListGroup(
                  children: [
                    ListRow(
                      leading: const IconTile(Icons.edit_outlined),
                      title: 'Edit profile',
                      onTap: () => context.push('/profile-edit'),
                    ),
                    ListRow(
                      leading: const IconTile(Icons.flag_outlined),
                      title: 'Learning goal',
                      subtitle: value.learningGoal ?? 'Not selected',
                      chevron: false,
                    ),
                    ListRow(
                      leading: const IconTile(Icons.interests_outlined),
                      title: 'Interests',
                      subtitle: value.interests.isEmpty
                          ? 'Not selected'
                          : value.interests.join(', '),
                      chevron: false,
                    ),
                  ],
                ),
                ListRow(
                  leading: const IconTile(
                    Icons.logout_rounded,
                    tone: Tone.danger,
                  ),
                  title: 'Log out',
                  onTap: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            ),
    );
  }
}

extension on Profile {
  String get emailSafeLabel => phone.isEmpty
      ? 'Email managed by Firebase Authentication'
      : 'Phone verified for account contact';
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
