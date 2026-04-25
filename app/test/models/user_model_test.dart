import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel.fromMap should create a valid instance', () {
      final map = {
        'uid': 'test-uid',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'role': 'admin',
        'piecesOr': 100,
        'lastLoginAt': '2023-10-27T10:00:00Z',
      };

      final user = UserModel.fromMap(map);

      expect(user.uid, 'test-uid');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.role, 'admin');
      expect(user.piecesOr, 100);
      expect(user.lastLoginAt, DateTime.parse('2023-10-27T10:00:00Z'));
      expect(user.isAdmin, isTrue);
      expect(user.isSuperAdmin, isFalse);
    });

    test('UserModel.toMap should return a valid map', () {
      final lastLogin = DateTime.now();
      final user = UserModel(
        uid: 'uid-123',
        email: 'user@test.com',
        displayName: 'User Name',
        role: 'superAdmin',
        piecesOr: 500,
        lastLoginAt: lastLogin,
      );

      final map = user.toMap();

      expect(map['uid'], 'uid-123');
      expect(map['email'], 'user@test.com');
      expect(map['displayName'], 'User Name');
      expect(map['role'], 'superAdmin');
      expect(map['piecesOr'], 500);
      expect(map['lastLoginAt'], lastLogin.toIso8601String());
      expect(user.isAdmin, isTrue);
      expect(user.isSuperAdmin, isTrue);
    });

    test('UserModel.copyWith should return a new instance with updated values', () {
      final user = UserModel(
        uid: 'original-uid',
        email: 'original@test.com',
        displayName: 'Original Name',
      );

      final updatedUser = user.copyWith(
        displayName: 'Updated Name',
        piecesOr: 250,
      );

      expect(updatedUser.uid, 'original-uid');
      expect(updatedUser.email, 'original@test.com');
      expect(updatedUser.displayName, 'Updated Name');
      expect(updatedUser.piecesOr, 250);
      expect(user.displayName, 'Original Name'); // Ensure original is unchanged
    });
  });
}
