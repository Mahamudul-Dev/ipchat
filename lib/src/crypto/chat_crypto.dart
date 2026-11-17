import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Handles zero-knowledge key derivation and AES-256-GCM encryption/decryption.
class ChatCrypto {
  final enc.Encrypter _encrypter;
  final String roomId;

  ChatCrypto._({required enc.Encrypter encrypter, required this.roomId})
      : _encrypter = encrypter;

  /// Creates a [ChatCrypto] instance from a user-provided passphrase.
  ///
  /// Throws [ArgumentError] if the password is shorter than 6 characters.
  factory ChatCrypto.fromPassword(String password) {
    if (password.length < 6) {
      throw ArgumentError('Password too short. Use at least 6 characters.');
    }

    // Derive 256-bit encryption key
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

    // Zero-Knowledge Room ID: truncated SHA-256 hash of the derived key
    final roomId = sha256.convert(keyBytes).toString().substring(0, 16);

    return ChatCrypto._(encrypter: encrypter, roomId: roomId);
  }

  /// Encrypts plain text using AES-256-GCM with a secure 16-byte random IV.
  ///
  /// Returns a transmission string: `[Base64 IV (24 chars)][Base64 Ciphertext + Tag]`.
  String encrypt(String plainText) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return iv.base64 + encrypted.base64;
  }

  /// Decrypts a received payload string.
  ///
  /// Returns the decrypted plain text, or null if decryption fails (e.g., wrong key or corrupted packet).
  String? decrypt(String payload) {
    if (payload.length <= 24) return null;
    try {
      final iv = enc.IV.fromBase64(payload.substring(0, 24));
      final encryptedText = enc.Encrypted.fromBase64(payload.substring(24));
      return _encrypter.decrypt(encryptedText, iv: iv);
    } catch (_) {
      return null;
    }
  }
}
