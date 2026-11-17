import 'dart:io';

/// Represents a connected peer session on the relay server.
class ClientSession {
  final InternetAddress ip;
  final int port;
  final String id;
  DateTime lastSeen;

  ClientSession({
    required this.ip,
    required this.port,
    required this.id,
  }) : lastSeen = DateTime.now();

  /// Refreshes the last active timestamp to current time.
  void touch() {
    lastSeen = DateTime.now();
  }

  /// Checks whether the client has been inactive for longer than [timeoutSeconds].
  bool isInactive(int timeoutSeconds) {
    return DateTime.now().difference(lastSeen).inSeconds > timeoutSeconds;
  }
}
