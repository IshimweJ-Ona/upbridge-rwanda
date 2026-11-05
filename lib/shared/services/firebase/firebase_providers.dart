// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/services/firebase/auth_service.dart';
import 'package:upbridge/shared/services/firebase/upbridge_repository.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final repositoryProvider = Provider<UpBridgeRepository>((ref) => UpBridgeRepository());
