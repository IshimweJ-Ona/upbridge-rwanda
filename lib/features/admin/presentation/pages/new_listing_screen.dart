// Collects and validates a new opportunity listing for the pilot.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// AD7 · New listing (with a reply-by date and a no-fee confirmation).
class NewListingScreen extends ConsumerStatefulWidget {
  const NewListingScreen({super.key});

  @override
  ConsumerState<NewListingScreen> createState() => _NewListingScreenState();
}

class _NewListingScreenState extends ConsumerState<NewListingScreen> {
  static const _types = ['Internship', 'Job', 'Gig', 'Trainee'];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  final _title = TextEditingController();
  final _org = TextEditingController();
  final _pay = TextEditingController();
  final _place = TextEditingController();
  final _about = TextEditingController();
  String _type = 'Job';
  DateTime? _closes;
  DateTime? _replyBy;
  bool _noFee = false;
  bool _tried = false;
  bool _saving = false;
  int _shake = 0;

  @override
  void dispose() {
    for (final c in [_title, _org, _pay, _place, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmt(DateTime d) => '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  void _example() {
    HapticFeedback.selectionClick();
    setState(() {
      _title.text = 'Excel reporting assistant';
      _org.text = 'Ikawa Hills Cooperative';
      _pay.text = 'RWF 120,000 / month';
      _place.text = 'Huye · on-site';
      _about.text = 'Keep the cooperative’s coffee delivery records in Excel and prepare a simple weekly report for the board.';
      _type = 'Job';
      _closes = DateTime(2026, 11, 6);
      _replyBy = DateTime(2026, 11, 20);
    });
  }

  Future<void> _pick({required bool closes}) async {
    final now = DateTime(2026, 10, 17);
    final picked = await showDatePicker(
      context: context,
      initialDate: (closes ? _closes : _replyBy) ?? (closes ? DateTime(2026, 10, 31) : (_closes ?? now).add(const Duration(days: 14))),
      firstDate: now,
      lastDate: DateTime(2027, 6, 30),
      helpText: closes ? 'Applications close' : 'Employer replies by',
    );
    if (picked == null) return;
    setState(() {
      if (closes) {
        _closes = picked;
      } else {
        _replyBy = picked;
      }
    });
  }

  bool get _requireReplyBy => ref.read(appStoreProvider).settings['replyBy'] ?? true;

  String? _err(TextEditingController c, String msg) => _tried && c.text.trim().length < 2 ? msg : null;
  String? get _closesError => _tried && _closes == null ? 'Choose a closing date.' : null;
  String? get _replyError {
    if (!_tried) return null;
    if (_replyBy == null) return _requireReplyBy ? 'A reply-by date is required for every listing.' : null;
    if (_closes != null && _replyBy!.isBefore(_closes!)) return 'Reply-by must be after the closing date.';
    return null;
  }

  int get _errors => [
        _err(_title, ''),
        _err(_org, ''),
        _err(_pay, ''),
        _err(_place, ''),
        _closesError,
        _replyError,
        _tried && !_noFee ? '' : null,
      ].where((e) => e != null).length;

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    setState(() => _tried = true);
    if (_errors > 0) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final days = _closes!.difference(DateTime(2026, 10, 17)).inDays;
    ref.read(appStoreProvider.notifier).publishListing(
          Opportunity(
            id: 'l-${DateTime.now().millisecondsSinceEpoch}',
            title: _title.text.trim(),
            org: _org.text.trim(),
            orgTone: Tone.success,
            kind: _type.toUpperCase(),
            length: '',
            pay: _pay.text.trim().toUpperCase(),
            place: _place.text.trim(),
            closes: _fmt(_closes!),
            closesNote: '$days DAYS LEFT',
            repliesBy: _replyBy == null ? '—' : _fmt(_replyBy!),
            starts: 'To be agreed',
            about: _about.text.trim(),
            aboutOrg: _org.text.trim(),
            tasks: const [],
            requirements: const [],
            category: _type == 'Job' ? 'Jobs' : (_type == 'Internship' ? 'Internships' : (_type == 'Gig' ? 'Gigs' : 'Trainee')),
            posted: 'Posted today',
            postedBy: 'Added by an UpBridge admin',
          ),
        );
    showToast(context, 'Listing published — matched youth are notified');
    goBack(context, fallback: '/a/jobs');
  }

  @override
  Widget build(BuildContext context) {
    final requireReply = ref.watch(appStoreProvider.select((s) => s.settings['replyBy'] ?? true));
    return DetailPage(
      title: 'New listing',
      closeIcon: true,
      backFallback: '/a/jobs',
      footer: [AppButton('Publish listing', icon: Icons.publish_rounded, loading: _saving, onPressed: _publish)],
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(child: PageHeading(title: 'Add a listing', body: 'Only real roles with clear pay. No fees, ever.', bottom: 0)),
            TextLink('Use example', onTap: _example),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          child: _tried && _errors > 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NoticeCard(tone: Tone.danger, icon: Icons.error_outline_rounded, title: 'Fix $_errors ${_errors == 1 ? 'field' : 'fields'} to publish'),
                )
              : const SizedBox(width: double.infinity),
        ),
        Shake(
          trigger: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(label: 'Role title', controller: _title, hint: 'e.g. Excel reporting assistant', error: _err(_title, 'Add the role title.'), onChanged: (_) => _refresh()),
              const SizedBox(height: 16),
              AppTextField(label: 'Organisation', controller: _org, hint: 'e.g. Ikawa Hills Cooperative', error: _err(_org, 'Add the organisation.'), onChanged: (_) => _refresh()),
              const SizedBox(height: 16),
              Text('Type', style: AppText.bodySStrong),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final t in _types) SelectChip(label: t, selected: _type == t, onTap: () => setState(() => _type = t))],
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Pay', controller: _pay, hint: 'e.g. RWF 120,000 / month', error: _err(_pay, 'Listings must show pay.'), onChanged: (_) => _refresh()),
              const SizedBox(height: 16),
              AppTextField(label: 'Location', controller: _place, hint: 'e.g. Huye · on-site', error: _err(_place, 'Add where the work happens.'), onChanged: (_) => _refresh()),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      key: ValueKey('closes-$_closes'),
                      label: 'Closes',
                      initialValue: _closes == null ? '' : _fmt(_closes!),
                      hint: 'Choose date',
                      readOnly: true,
                      suffixIcon: Icons.calendar_today_outlined,
                      error: _closesError,
                      onTap: () => _pick(closes: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      key: ValueKey('reply-$_replyBy'),
                      label: requireReply ? 'Replies by' : 'Replies by (optional)',
                      initialValue: _replyBy == null ? '' : _fmt(_replyBy!),
                      hint: 'Choose date',
                      readOnly: true,
                      suffixIcon: Icons.event_available_outlined,
                      error: _replyError,
                      onTap: () => _pick(closes: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'About the role', controller: _about, maxLines: 5, minLines: 3, hint: 'What the person will do, and who they’ll work with.'),
              const SizedBox(height: 18),
              CheckRow(
                label: 'The employer confirmed applicants never pay a fee to apply or start.',
                value: _noFee,
                error: _tried && !_noFee ? 'Required for every listing.' : null,
                onChanged: (v) => setState(() => _noFee = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _refresh() {
    if (_tried) setState(() {});
  }
}
