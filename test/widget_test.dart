import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/features/auth/domain/models/user_model.dart';

/// Smoke test that core enums are wired. Full widget tests would require
/// pumping the app with a ProviderScope; the behavioural logic is covered by
/// the unit tests in the sibling *_test.dart files.
void main() {
  test('smoke: UserRole has six roles', () {
    expect(UserRole.values.length, 6);
    expect(UserRole.values, contains(UserRole.seniorTechnician));
    expect(UserRole.values, contains(UserRole.clientAdmin));
  });
}
