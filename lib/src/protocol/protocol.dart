/// Defines the protocol command strings exchanged between the client and relay.
class Protocol {
  static const String joinPrefix = '[JOIN]';
  static const String joined = '[JOINED]';
  static const String ping = '[PING]';
  static const String pong = '[PONG]';
  static const String leave = '[LEAVE]';

  /// Builds a join packet for the specified [roomId].
  static String buildJoin(String roomId) => '$joinPrefix $roomId';

  /// Extracts the room ID from a join message. Returns null if invalid.
  static String? extractRoomId(String message) {
    if (!message.startsWith(joinPrefix)) return null;
    final parts = message.split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return parts[1];
    }
    return null;
  }

  /// Checks if a message is an internal heartbeat/system packet.
  static bool isSystemPacket(String message) {
    return message == ping || message == pong || message == leave;
  }
}
