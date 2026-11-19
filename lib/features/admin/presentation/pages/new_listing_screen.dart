// Collects and validates a new opportunity listing for the pilot in demo state.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/core/utils/kigali_time.dart';
import 'package:upbridge/features/admin/domain/entities/listing_draft.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/shared.dart';

/// AD7 · New listing (with a reply-by date and a no-fee confirmation).
class NewListingScreen extends ConsumerStatefulWidget {
  const NewListingScreen({super.key});

  @override
  ConsumerState<NewListingScreen> createState() => _NewListingScreenState();
}

class _NewListingScreenState extends ConsumerState<NewListingScreen> {
  static const _types = ['Internship', 'Job', 'Gig', 'Trainee'];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

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

  DateTime get _kigaliToday => KigaliTime.startOfDay(DateTime.now());

  static String _fmt(DateTime d) =>
      '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  void _example() {
    HapticFeedback.selectionClick();
    final today = _kigaliToday;
    setState(() {
      _title.text = 'Excel reporting assistant';
      _org.text = 'Ikawa Hills Cooperative';
      _pay.text = 'RWF 120,000 / month';
      _place.text = 'Huye · on-site';
      _about.text = 'Keep the cooperative’s coffee delivery records in Excel and prepare a simple weekly report for the board.';
      _type = 'Job';
      _closes = today.add(const Duration(days: 20));
      _replyBy = today.add(const Duration(days: 34));
    });
  }

  Future<void> _pick({required bool closes}) async {
    final today = _kigaliToday;
    final defaultInitial = closes
        ? today.add(const Duration(days: 14))
        : (_closes ?? today).add(const Duration(days: 14));
    final candidate = (closes ? _closes : _replyBy) ?? defaultInitial;
    final initialDate = candidate.isBefore(today) ? today : candidate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
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

  bool get _requireReplyBy =>
      ref.read(appStoreProvider).settings['replyBy'] ?? true;

  ListingDraft get _draft => ListingDraft(
    title: _title.text,
    organization: _org.text,
    pay: _pay.text,
    location: _place.text,
    description: _about.text,
    noFeeConfirmed: _noFee,
    closesAt: _closes,
    replyBy: _replyBy,
  );

  String? _err(TextEditingController c, String msg) =>
      _tried && c.text.trim().length < 2 ? msg : null;

  String? get _payError =>
      _tried && _pay.text.trim().isEmpty ? 'Listings must show pay.' : null;

  String? get _placeError => _tried && _place.text.trim().isEmpty
      ? 'Add where the work happens.'
      : null;

  String? get _closesError =>
      _tried && _closes == null ? 'Choose a closing date.' : null;

  String? get _replyError {
    if (!_tried) return null;
    if (_replyBy == null) {
      return _requireReplyBy
          ? 'A reply-by date is required for every listing.'
          : null;
    }
    if (_closes != null && _replyBy!.isBefore(_closes!)) {
      return 'Reply-by must be after the closing date.';
    }
    return null;
  }

  List<String> get _validationErrors =>
      _tried ? _draft.validate(replyByRequired: _requireReplyBy) : const [];

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    setState(() => _tried = true);
    if (_validationErrors.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final days = _closes!.difference(_kigaliToday).inDays;
    ref
        .read(appStoreProvider.notifier)
        .publishListing(
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
            closesNote: days <= 0 ? 'CLOSES TODAY' : '$days DAYS LEFT',
            repliesBy: _replyBy == null ? '—' : _fmt(_replyBy!),
            starts: 'To be agreed',
            about: _about.text.trim(),
            aboutOrg: _org.text.trim(),
            tasks: const [],
            requirements: const [],
            category: _type == 'Job'
                ? 'Jobs'
                : (_type == 'Internship'
                      ? 'Internships'
                      : (_type == 'Gig' ? 'Gigs' : 'Trainee')),
            posted: 'Posted today',
            postedBy: 'Added by an UpBridge admin',
          ),
        );
    showToast(context, 'Listing published in demo state');
    goBack(context, fallback: '/a/jobs');
  }

  @override
  Widget build(BuildContext context) {
    final requireReply = ref.watch(
      appStoreProvider.select((s) => s.settings['replyBy'] ?? true),
    );
    final errorCount = _validationErrors.length;
    return DetailPage(
      title: 'New listing',
      closeIcon: true,
      backFallback: '/a/jobs',
      footer: [
        AppButton(
          'Publish listing',
          icon: Icons.publish_rounded,
          loading: _saving,
          onPressed: _publish,
        ),
      ],
      children: [
        const SizedBox(height: 8),
        const NoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Demonstration data',
          body: 'Listings created here are stored only in local demo state.',
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: PageHeading(
                title: 'Add a listing',
                body: 'Only real roles with clear pay. No fees, ever.',
                bottom: 0,
              ),
            ),
            TextLink('Use example', onTap: _example),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          child: _tried && errorCount > 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NoticeCard(
                    tone: Tone.danger,
                    icon: Icons.error_outline_rounded,
                    title:
                        'Fix $errorCount ${errorCount == 1 ? 'field' : 'fields'} to publish',
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Shake(
          trigger: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Role title',
                controller: _title,
                hint: 'e.g. Excel reporting assistant',
                error: _err(_title, 'Add the role title.'),
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Organisation',
                controller: _org,
                hint: 'e.g. Ikawa Hills Cooperative',
                error: _err(_org, 'Add the organisation.'),
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 16),
              Text('Type', style: AppText.bodySStrong),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _types)
                    SelectChip(
                      label: t,
                      selected: _type == t,
                      onTap: () => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Pay',
                controller: _pay,
                hint: 'e.g. RWF 120,000 / month',
                error: _payError,
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Location',
                controller: _place,
                hint: 'e.g. Huye · on-site',
                error: _placeError,
                onChanged: (_) => _refresh(),
              ),
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
                      label: requireReply
                          ? 'Replies by'
                          : 'Replies by (optional)',
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
              AppTextField(
                label: 'About the role',
                controller: _about,
                maxLines: 5,
                minLines: 3,
                hint: 'What the person will do, and who they’ll work with.',
                error: _err(_about, 'Describe the role.'),
                onChanged: (_) => _refresh(),
              ),
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
