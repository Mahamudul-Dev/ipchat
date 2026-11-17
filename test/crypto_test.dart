import 'package:ipchat/ipchat.dart';
import 'package:test/test.dart';

void main() {
  group('ChatCrypto', () {
    test('derives 16-character room ID from password', () {
      final crypto = ChatCrypto.fromPassword('mySecretPass123');
      expect(crypto.roomId, hasLength(16));
    });

    test('rejects passwords shorter than 6 characters', () {
      expect(
        () => ChatCrypto.fromPassword('short'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('encrypts and decrypts payload successfully', () {
      final crypto = ChatCrypto.fromPassword('securePassword2026');
      const plainText = 'Hello, this is a secret E2EE message!';

      final encrypted = crypto.encrypt(plainText);
      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted.length, greaterThan(24));

      final decrypted = crypto.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('fails to decrypt with a different password', () {
      final crypto1 = ChatCrypto.fromPassword('passwordOne123');
      final crypto2 = ChatCrypto.fromPassword('passwordTwo456');

      final encrypted = crypto1.encrypt('Sensitive information');
      final decrypted = crypto2.decrypt(encrypted);

      expect(decrypted, isNull);
    });

    test('gracefully returns null on malformed payload', () {
      final crypto = ChatCrypto.fromPassword('myStrongPass99');
      expect(crypto.decrypt('too_short'), isNull);
      expect(crypto.decrypt('invalid_base64_payload_string_that_fails_parsing'), isNull);
    });
  });
}
