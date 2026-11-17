import 'dart:convert';

/// Represents a decrypted chat message exchanged between peers.
class ChatMessage {
  final String username;
  final String message;
  final String timestamp;

  ChatMessage({
    required this.username,
    required this.message,
    required this.timestamp,
  });

  /// Serializes message to a compact JSON string.
  String toJsonString() {
    return jsonEncode({
      'u': username,
      'm': message,
      't': timestamp,
    });
  }

  /// Parses a compact JSON string into a [ChatMessage]. Returns null if malformed.
  static ChatMessage? fromJsonString(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        final u = data['u'] as String?;
        final m = data['m'] as String?;
        final t = (data['t'] as String?) ?? '';
        if (u != null && m != null) {
          return ChatMessage(username: u, message: m, timestamp: t);
        }
      }
    } catch (_) {}
    return null;
  }
}
