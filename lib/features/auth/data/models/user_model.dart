import 'package:firebase_auth/firebase_auth.dart';

import 'package:upbridge/features/profile/domain/entities/profile.dart';

class UserModel {
  const UserModel({required this.authUser, this.profile});

  final User authUser;
  final Profile? profile;

  Profile toProfile() =>
      profile ??
      Profile(
        uid: authUser.uid,
        role: 'youth',
        accountStatus: 'active',
        displayName: authUser.displayName ?? '',
        phone: '',
        onboarded: false,
      );
}
