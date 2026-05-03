import 'package:flutter_test/flutter_test.dart';
import 'package:adms/core/models/user.dart';
import 'package:adms/core/models/user_role.dart';

void main() {
  group('User', () {
    final now = DateTime(2025, 1, 15, 10, 30);

    User createTestUser({
      String id = 'user-1',
      UserRole role = UserRole.municipalAdmin,
    }) {
      return User(
        id: id,
        email: 'juan@example.com',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        phoneNumber: '09171234567',
        role: role,
        municipalityId: 'mun-1',
        municipalityName: 'Test Municipality',
        isVerified: true,
        isActive: true,
        isApproved: true,
        createdAt: now,
      );
    }

    test('fullName returns first and last name', () {
      final user = createTestUser();
      expect(user.fullName, 'Juan Dela Cruz');
    });

    test('initials returns uppercase first letters', () {
      final user = createTestUser();
      expect(user.initials, 'JD');
    });

    test('isSuperAdmin returns true only for superAdmin role', () {
      expect(createTestUser(role: UserRole.superAdmin).isSuperAdmin, isTrue);
      expect(createTestUser(role: UserRole.municipalAdmin).isSuperAdmin, isFalse);
      expect(createTestUser(role: UserRole.driver).isSuperAdmin, isFalse);
      expect(createTestUser(role: UserRole.citizen).isSuperAdmin, isFalse);
    });

    test('isAdmin returns true for superAdmin and municipalAdmin', () {
      expect(createTestUser(role: UserRole.superAdmin).isAdmin, isTrue);
      expect(createTestUser(role: UserRole.municipalAdmin).isAdmin, isTrue);
      expect(createTestUser(role: UserRole.driver).isAdmin, isFalse);
    });

    test('canDispatch returns true for admin and dispatcher roles', () {
      expect(createTestUser(role: UserRole.superAdmin).canDispatch, isTrue);
      expect(createTestUser(role: UserRole.municipalAdmin).canDispatch, isTrue);
      expect(createTestUser(role: UserRole.driver).canDispatch, isFalse);
      expect(createTestUser(role: UserRole.citizen).canDispatch, isFalse);
    });

    test('toJson serializes all fields', () {
      final user = createTestUser();
      final json = user.toJson();

      expect(json['id'], 'user-1');
      expect(json['email'], 'juan@example.com');
      expect(json['firstName'], 'Juan');
      expect(json['lastName'], 'Dela Cruz');
      expect(json['phoneNumber'], '09171234567');
      expect(json['role'], 'municipalAdmin');
      expect(json['municipalityId'], 'mun-1');
      expect(json['municipalityName'], 'Test Municipality');
      expect(json['isVerified'], isTrue);
      expect(json['isActive'], isTrue);
      expect(json['isApproved'], isTrue);
      expect(json['createdAt'], now.toIso8601String());
    });

    test('fromJson deserializes correctly', () {
      final user = createTestUser();
      final json = user.toJson();
      final deserialized = User.fromJson(json);

      expect(deserialized.id, user.id);
      expect(deserialized.email, user.email);
      expect(deserialized.firstName, user.firstName);
      expect(deserialized.lastName, user.lastName);
      expect(deserialized.role, user.role);
      expect(deserialized.municipalityId, user.municipalityId);
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = createTestUser().copyWith(
        avatarUrl: 'https://example.com/avatar.jpg',
        lastLoginAt: DateTime(2025, 1, 16),
      );
      final roundTripped = User.fromJson(original.toJson());

      expect(roundTripped.avatarUrl, original.avatarUrl);
      expect(roundTripped.lastLoginAt, original.lastLoginAt);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'user-2',
        'email': 'test@example.com',
        'firstName': 'Test',
        'lastName': 'User',
        'role': 'citizen',
        'createdAt': now.toIso8601String(),
      };
      final user = User.fromJson(json);

      expect(user.phoneNumber, isNull);
      expect(user.municipalityId, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.lastLoginAt, isNull);
      expect(user.isVerified, isFalse);
      expect(user.isApproved, isFalse);
    });

    test('copyWith updates only specified fields', () {
      final user = createTestUser();
      final updated = user.copyWith(
        role: UserRole.municipalAdmin,
        isApproved: false,
      );

      expect(updated.role, UserRole.municipalAdmin);
      expect(updated.isApproved, isFalse);
      // Unchanged fields
      expect(updated.id, user.id);
      expect(updated.email, user.email);
      expect(updated.firstName, user.firstName);
    });

    test('equality based on props', () {
      final user1 = createTestUser();
      final user2 = createTestUser();
      expect(user1, equals(user2));

      final different = createTestUser(id: 'user-other');
      expect(user1, isNot(equals(different)));
    });
  });
}
