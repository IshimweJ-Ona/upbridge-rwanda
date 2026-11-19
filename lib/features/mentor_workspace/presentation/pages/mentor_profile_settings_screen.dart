// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/models/models.dart' show initialsOf;
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/features/profile/presentation/pages/language_screen.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/availability_window.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentor_profile.dart';
import 'package:upbridge/features/mentor_workspace/presentation/pages/mentor_home_screen.dart';
import 'package:upbridge/features/mentor_workspace/presentation/providers/mentor_providers.dart';

/// MP1 · Mentor profile and availability (mentorProfiles/{uid}).
class MentorProfileSettingsScreen extends ConsumerWidget {
  const MentorProfileSettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showAppDialog(
      context,
      title: 'Log out?',
      body: 'Your reviews and notes are saved.',
      confirmLabel: 'Log out',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (ok) ref.read(appStoreProvider.notifier).logout();
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    try {
      final saved = await ref.read(profileEditProvider.notifier).save();
      if (saved && context.mounted) showToast(context, 'Profile saved');
    } catch (error) {
      if (context.mounted) {
        showToast(context, mentorshipErrorText(error), icon: Icons.error_outline_rounded, tone: Tone.danger);
      }
    }
  }

  Future<void> _addWindow(BuildContext context, WidgetRef ref, MentorProfile current) async {
    final window = await showAppSheet<AvailabilityWindow>(context, title: 'Add a time', builder: (_) => const AddWindowSheet());
    if (window == null) return;
    ref.read(profileEditProvider.notifier).edit(current.copyWith(windows: [...current.windows, window]));
  }

  Future<void> _editLink(BuildContext context, WidgetRef ref, MentorProfile current) async {
    final link = await showAppSheet<String>(context, title: 'Meeting link', builder: (_) => MeetingLinkSheet(initial: current.meetingLink));
    if (link == null) return;
    ref.read(profileEditProvider.notifier).edit(current.copyWith(meetingLink: link));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final profileAsync = ref.watch(myMentorProfileProvider);
    final edit = ref.watch(profileEditProvider);
    final saved = profileAsync.value;
    final profile = edit.draft ?? saved;
    final problem = edit.draft?.validate();

    final account = [
      const SectionLabel('Account'),
      ListGroup(
        children: [
          ListRow(
            leading: const IconTile(Icons.translate_rounded),
            title: 'Language',
            trailing: Text(LanguageScreen.labelFor(data.language), style: AppText.bodyS),
            onTap: () => context.push('/language'),
          ),
          ListRow(
            leading: const IconTile(Icons.menu_book_outlined),
            title: 'Review guide',
            onTap: () => showAppSheet<void>(context, title: 'Review guide', builder: (_) => const ReviewGuide()),
          ),
          ListRow(
            leading: const IconTile(Icons.logout_rounded, tone: Tone.danger),
            title: 'Log out',
            titleStyle: AppText.bodyMStrong.copyWith(color: AppColors.dangerText),
            chevron: false,
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    ];

    if (profile == null) {
      return PageFrame(
        largeTitle: 'Profile',
        eyebrow: data.user?.phone,
        children: [
          const SizedBox(height: 16),
          if (profileAsync.hasError)
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load your profile',
              body: mentorshipErrorText(profileAsync.error!),
              action: 'Try again',
              onAction: () => ref.invalidate(myMentorProfileProvider),
            )
          else if (profileAsync.isLoading)
            const Shimmer(child: SkeletonBox(height: 200, radius: Radii.lg))
          else
            const EmptyState(
              icon: Icons.badge_outlined,
              title: 'No mentor profile yet',
              body: 'Your profile is created when UpBridge verifies you as a mentor.',
            ),
          ...account,
        ],
      );
    }

    final windows = profile.sortedWindows;
    final open = windows.length;

    return PageFrame(
      largeTitle: 'Profile',
      eyebrow: data.user?.phone,
      footerNote: edit.draft == null
          ? null
          : Text(problem ?? 'You have unsaved changes', style: AppText.caption.copyWith(color: problem == null ? null : AppColors.dangerText)),
      footer: edit.draft == null
          ? null
          : [
              AppButton('Save changes', loading: edit.saving, onPressed: problem != null || edit.saving ? null : () => _save(context, ref)),
              AppButton('Discard', variant: ButtonVariant.secondary, onPressed: edit.saving ? null : () => ref.read(profileEditProvider.notifier).discard()),
            ],
      children: [
        const SizedBox(height: 16),
        SurfaceCard(
          child: Row(
            children: [
              AppAvatar(initialsOf(profile.name), tone: Tone.accent, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: AppText.titleM),
                    if (profile.title.isNotEmpty || profile.employer.isNotEmpty)
                      Text([profile.title, profile.employer].where((s) => s.isNotEmpty).join(' · '), style: AppText.bodyS),
                    const SizedBox(height: 6),
                    profile.verified
                        ? const StatusBadge('Verified mentor', tone: Tone.success, icon: Icons.verified_rounded)
                        : const StatusBadge('Waiting for verification', tone: Tone.warning),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatStrip([
          StatItem('', 'Reviews', countTo: profile.reviewsCount),
          StatItem(profile.replyTime, 'Median reply'),
          StatItem('', 'Mentees', countTo: profile.menteeCount),
        ]),
        SectionLabel('Availability · $open ${open == 1 ? 'slot' : 'slots'} a week'),
        ListGroup(
          children: [
            for (final w in windows)
              ListRow(
                leading: const IconTile(Icons.schedule_rounded, tone: Tone.info),
                title: w.label,
                chevron: false,
                trailing: IconButton(
                  tooltip: 'Remove ${w.label}',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => ref.read(profileEditProvider.notifier).edit(profile.copyWith(windows: [...profile.windows]..remove(w))),
                ),
              ),
            ListRow(
              leading: const IconTile(Icons.add_rounded, tone: Tone.info),
              title: 'Add a time',
              onTap: () => _addWindow(context, ref, profile),
            ),
            ListRow(
              leading: const IconTile(Icons.person_add_alt_outlined, tone: Tone.accent),
              title: 'Accepting new mentees',
              subtitle: profile.accepting ? 'You appear in the Mentors list' : 'Hidden from new youth',
              chevron: false,
              trailing: AppSwitch(value: profile.accepting, onChanged: (v) => ref.read(profileEditProvider.notifier).edit(profile.copyWith(accepting: v))),
              onTap: () => ref.read(profileEditProvider.notifier).edit(profile.copyWith(accepting: !profile.accepting)),
            ),
            ListRow(
              leading: const IconTile(Icons.videocam_outlined, tone: Tone.info),
              title: 'Meeting link',
              subtitle: profile.meetingLink.isEmpty ? 'Shared with youth when you accept' : profile.meetingLink,
              onTap: () => _editLink(context, ref, profile),
            ),
          ],
        ),
        const SectionLabel('Expertise'),
        if (profile.skills.isEmpty)
          Text('No skills listed yet.', style: AppText.bodyS)
        else
          TagWrap(profile.skills, tone: Tone.info),
        ...account,
      ],
    );
  }
}

/// Picks a weekday and a start and end hour.
class AddWindowSheet extends StatefulWidget {
  const AddWindowSheet({super.key});

  @override
  State<AddWindowSheet> createState() => _AddWindowSheetState();
}

class _AddWindowSheetState extends State<AddWindowSheet> {
  static final _hours = [for (var h = 6; h <= 22; h++) h];
  static const _short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _day = _short[1];
  int _start = 18;
  int _end = 20;

  String _hh(int h) => '${h.toString().padLeft(2, '0')}:00';

  AvailabilityWindow get _window => AvailabilityWindow(weekday: _short.indexOf(_day) + 1, startMinutes: _start * 60, endMinutes: _end * 60);

  @override
  Widget build(BuildContext context) {
    final problem = _window.validate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Day', style: AppText.bodyMStrong),
        const SizedBox(height: 8),
        ChipBar(options: _short, selected: _day, padding: EdgeInsets.zero, onSelected: (v) => setState(() => _day = v)),
        const SizedBox(height: 16),
        Text('Starts', style: AppText.bodyMStrong),
        const SizedBox(height: 8),
        ChipBar(options: [for (final h in _hours) _hh(h)], selected: _hh(_start), padding: EdgeInsets.zero, onSelected: (v) => setState(() => _start = int.parse(v.substring(0, 2)))),
        const SizedBox(height: 16),
        Text('Ends', style: AppText.bodyMStrong),
        const SizedBox(height: 8),
        ChipBar(options: [for (final h in _hours) _hh(h)], selected: _hh(_end), padding: EdgeInsets.zero, onSelected: (v) => setState(() => _end = int.parse(v.substring(0, 2)))),
        const SizedBox(height: 12),
        Text(problem ?? _window.label, style: AppText.caption.copyWith(color: problem == null ? null : AppColors.dangerText)),
        const SizedBox(height: 16),
        AppButton('Add time', onPressed: problem == null ? () => Navigator.of(context).pop(_window) : null),
      ],
    );
  }
}

/// Edits the meeting link shared with youth on accepted sessions.
class MeetingLinkSheet extends StatefulWidget {
  const MeetingLinkSheet({super.key, required this.initial});

  final String initial;

  @override
  State<MeetingLinkSheet> createState() => _MeetingLinkSheetState();
}

class _MeetingLinkSheetState extends State<MeetingLinkSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final problem = MentorProfile(id: '', name: '', meetingLink: _controller.text).validate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          label: 'Link',
          controller: _controller,
          hint: 'https://meet.google.com/abc-defg-hij',
          keyboardType: TextInputType.url,
          error: _controller.text.trim().isEmpty ? null : problem,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppButton('Use this link', onPressed: problem == null ? () => Navigator.of(context).pop(_controller.text.trim()) : null),
      ],
    );
  }
}
