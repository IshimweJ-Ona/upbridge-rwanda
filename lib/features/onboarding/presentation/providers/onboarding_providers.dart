import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepositoryImpl>(
  (ref) => OnboardingRepositoryImpl(ref.watch(repositoryProvider)),
);
