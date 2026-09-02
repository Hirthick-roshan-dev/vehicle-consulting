import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_consulting/core/utils/password_hasher.dart';

void main() {
  group('PasswordHasher Tests', () {
    test('hash produces SHA-256 string digest', () {
      final h1 = PasswordHasher.hash('admin123');
      expect(h1, isNotEmpty);
      expect(h1.length, 64); // SHA-256 hex string length
    });

    test('verify correctly checks matching inputs', () {
      final hash = PasswordHasher.hash('secretPass123');
      expect(PasswordHasher.verify('secretPass123', hash), isTrue);
      expect(PasswordHasher.verify('wrongPass', hash), isFalse);
    });
  });
}
