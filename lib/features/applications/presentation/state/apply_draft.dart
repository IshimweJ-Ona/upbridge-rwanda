// Owner: Student 4 · Opportunities & applications
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the person has chosen on the apply screen, kept until they send it.
class ApplyDraft {
  const ApplyDraft({this.projectIds = const [], this.note = '', this.consent = false});

  final List<String> projectIds;
  final String note;
  final bool consent;
}

class ApplyDrafts extends Notifier<Map<String, ApplyDraft>> {
  @override
  Map<String, ApplyDraft> build() => const {};

  void save(String oppId, ApplyDraft draft) => state = {...state, oppId: draft};

  void clear(String oppId) => state = {
        for (final e in state.entries)
          if (e.key != oppId) e.key: e.value,
      };
}

final applyDraftsProvider = NotifierProvider<ApplyDrafts, Map<String, ApplyDraft>>(ApplyDrafts.new);
