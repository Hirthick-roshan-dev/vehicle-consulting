import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  /// Hashes a plain text password or passkey using SHA-256.
  static String hash(String input) {
    if (input.isEmpty) return '';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if a plain text input matches a stored SHA-256 hash.
  static bool verify(String input, String storedHash) {
    if (input.isEmpty || storedHash.isEmpty) return false;
    return hash(input) == storedHash;
  }
}
