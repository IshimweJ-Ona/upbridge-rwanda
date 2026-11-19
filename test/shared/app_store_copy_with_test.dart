// Verifies AppData.copyWith preserves and replaces all lists including mentors.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

void main() {
  test(
    'AppData.copyWith updates mentors when supplied and preserves otherwise',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store = container.read(appStoreProvider);
      final originalMentors = store.mentors;
      expect(originalMentors, isNotEmpty);

      final withoutMentorsArg = store.copyWith(checkInDone: true);
      expect(withoutMentorsArg.mentors, same(originalMentors));
      expect(withoutMentorsArg.checkInDone, isTrue);

      final replacement = [
        const Mentor(
          id: 'mentor-custom',
          name: 'Aline Mukamana',
          title: 'Product Engineer',
          employer: 'Kigali Studio',
          years: 6,
          city: 'Kigali',
          bio: 'Mentors web learners.',
          skills: ['Flutter', 'Testing'],
          helpsWith: ['Portfolio reviews'],
          reviews: 12,
          replyTime: 'Replies in 1 day',
          mentees: 3,
          availability: 'Weekends',
          languages: 'English · Kinyarwanda',
          tone: Tone.info,
        ),
      ];

      final updated = store.copyWith(mentors: replacement);
      expect(updated.mentors, same(replacement));
      expect(updated.mentors.single.id, 'mentor-custom');
      expect(updated.notifications, same(store.notifications));
    },
  );
}
