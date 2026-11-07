import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/errors/failures.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:evergreen/web/screens/web_task_board_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows retry state when loading tasks fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.client),
          currentUserProvider.overrideWithValue(null),
          tasksProvider.overrideWith(
            (ref) async => throw const FailureException(NoConnectionFailure()),
          ),
        ],
        child: const MaterialApp(home: WebTaskBoardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
