// Defines the shared role and domain records used across app modules.
import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_colors.dart';

part 'learning.dart';
part 'mentorship.dart';
part 'opportunities.dart';
part 'portfolio.dart';
part 'notifications.dart';
part 'administration.dart';

enum Role { youth, mentor, admin }

extension RoleX on Role {
  String get label => switch (this) {
    Role.youth => 'Youth',
    Role.mentor => 'Mentor',
    Role.admin => 'Admin',
  };

  String get home => switch (this) {
    Role.youth => '/home',
    Role.mentor => '/m/home',
    Role.admin => '/a/overview',
  };
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.headline = '',
    this.location = 'Kigali',
    this.about = '',
    this.onboarded = true,
    this.isNewMentor = false,
  });

  final String id;
  final String name;
  final String phone;
  final Role role;
  final String headline;
  final String location;
  final String about;
  final bool onboarded;
  final bool isNewMentor;

  String get firstName => name.split(' ').first;
  String get initials => initialsOf(name);

  AppUser copyWith({
    String? name,
    String? headline,
    String? location,
    String? about,
    bool? onboarded,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    phone: phone,
    role: role,
    headline: headline ?? this.headline,
    location: location ?? this.location,
    about: about ?? this.about,
    onboarded: onboarded ?? this.onboarded,
    isNewMentor: isNewMentor,
  );
}

class Account {
  const Account({required this.phone, required this.user});
  final String phone;
  final AppUser user;
}
