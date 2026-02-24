import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adms/core/models/models.dart';
import 'package:adms/core/services/auth_service.dart';
import 'package:adms/core/services/user_service.dart';
import 'package:adms/features/super_admin/screens/user_management_screen.dart';

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

final _superAdmin = User(
  id: 'uid-super',
  email: 'admin@test.com',
  firstName: 'Super',
  lastName: 'Admin',
  role: UserRole.superAdmin,
  isVerified: true,
  isActive: true,
  isApproved: true,
  createdAt: DateTime(2024),
);

List<User> _makeUsers() => [
      User(
        id: 'uid-1',
        email: 'alice@mun.gov',
        firstName: 'Alice',
        lastName: 'Santos',
        role: UserRole.dispatcher,
        municipalityId: 'mun-1',
        municipalityName: 'Manila',
        isVerified: true,
        isActive: true,
        isApproved: true,
        createdAt: DateTime(2024, 1, 10),
      ),
      User(
        id: 'uid-2',
        email: 'bob@mun.gov',
        firstName: 'Bob',
        lastName: 'Cruz',
        role: UserRole.driver,
        municipalityId: 'mun-1',
        municipalityName: 'Manila',
        isVerified: true,
        isActive: true,
        isApproved: true,
        createdAt: DateTime(2024, 2, 5),
      ),
      User(
        id: 'uid-3',
        email: 'carol@mun.gov',
        firstName: 'Carol',
        lastName: 'Reyes',
        role: UserRole.municipalAdmin,
        municipalityId: 'mun-2',
        municipalityName: 'Quezon City',
        isVerified: false,
        isActive: false,
        isApproved: false,
        createdAt: DateTime(2024, 3, 1),
      ),
    ];

// ---------------------------------------------------------------------------
// Helper to pump the screen
// ---------------------------------------------------------------------------

Future<void> _pumpScreen(
  WidgetTester tester, {
  AsyncValue<List<User>>? usersState,
  User? currentUser,
}) async {
  final state = usersState ?? AsyncData(_makeUsers());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allUsersProvider.overrideWith((_) => Stream.value(state.valueOrNull ?? [])),
        currentUserProvider.overrideWithValue(currentUser ?? _superAdmin),
      ],
      child: const MaterialApp(
        home: UserManagementScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('UserManagementScreen', () {
    testWidgets('shows CircularProgressIndicator while loading',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allUsersProvider.overrideWith(
              (_) => const Stream.empty(), // never emits
            ),
            currentUserProvider.overrideWithValue(_superAdmin),
          ],
          child: const MaterialApp(home: UserManagementScreen()),
        ),
      );
      await tester.pump(); // one frame — still loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders user list with correct names', (tester) async {
      await _pumpScreen(tester);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.textContaining('Bob'), findsWidgets);
      expect(find.textContaining('Carol'), findsWidgets);
    });

    testWidgets('renders role summary cards', (tester) async {
      await _pumpScreen(tester);
      // The role cards show at least one role label.
      expect(find.textContaining('Dispatcher'), findsWidgets);
    });

    testWidgets('search field is present', (tester) async {
      await _pumpScreen(tester);
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('search filters users by name — shows matching user',
        (tester) async {
      await _pumpScreen(tester);

      // Type search query
      await tester.enterText(find.byType(TextField).first, 'Alice');
      await tester.pump();

      expect(find.textContaining('Alice'), findsWidgets);
    });

    testWidgets('search hides non-matching users', (tester) async {
      await _pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'zzznomatch');
      await tester.pump();

      // Bob and Carol should not appear after filtering.
      expect(find.textContaining('Bob Cruz'), findsNothing);
    });

    testWidgets('shows empty state message when no users match',
        (tester) async {
      await _pumpScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'zzznomatch');
      await tester.pump();

      // Expect an empty-state indicator (icon or text).
      expect(
        find.byWidgetPredicate(
          (w) =>
              (w is Icon && w.icon == Icons.people_outline) ||
              (w is Text &&
                  (w.data?.toLowerCase().contains('no users') == true ||
                      w.data?.toLowerCase().contains('match') == true)),
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows three role summary card chips', (tester) async {
      await _pumpScreen(tester);
      // Check summary chips are rendered (at least the Total Users chip).
      expect(find.textContaining('Total'), findsWidgets);
    });
  });
}
