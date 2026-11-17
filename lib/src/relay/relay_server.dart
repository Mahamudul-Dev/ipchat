import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../protocol/protocol.dart';
import 'client_session.dart';

/// Zero-Knowledge UDP packet forwarder that routes blind encrypted blobs between peers.
class RelayServer {
  final int port;
  RawDatagramSocket? _socket;
  Timer? _pruneTimer;

  // Map: RoomID -> List of connected peers
  final Map<String, List<ClientSession>> _rooms = {};
  // Map: "IP:Port" -> RoomID (for fast lookup on incoming messages)
  final Map<String, String> _clientRooms = {};

  RelayServer({required this.port});

  /// Starts listening for UDP packets on [port].
  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    } catch (e) {
      stderr.writeln('✖ Failed to bind UDP port $port: $e');
      exit(1);
    }

    print('🛡️ IPChat Zero-Knowledge Group Relay');
    print('📡 Listening on UDP port $port...');
    print('🔒 Ready to route encrypted blobs without inspection.\n');

    _startInactivityPruning();
    _registerShutdownHooks();

    _socket?.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket?.receive();
        if (datagram == null) return;

        _processDatagram(datagram);
      }
    });
  }

  void _processDatagram(Datagram datagram) {
    final senderIp = datagram.address;
    final senderPort = datagram.port;
    final clientId = '${senderIp.address}:$senderPort';
    final rawMessage = utf8.decode(datagram.data, allowMalformed: true).trim();

    // 1. Client Join Request
    if (rawMessage.startsWith(Protocol.joinPrefix)) {
      final roomId = Protocol.extractRoomId(rawMessage);
      if (roomId == null) return;

      _rooms.putIfAbsent(roomId, () => []);
      final roomClients = _rooms[roomId]!;

      final existingIndex = roomClients.indexWhere((c) => c.id == clientId);
      if (existingIndex != -1) {
        roomClients[existingIndex].touch();
      } else {
        roomClients.add(ClientSession(ip: senderIp, port: senderPort, id: clientId));
        _clientRooms[clientId] = roomId;
      }

      // Acknowledge connection
      _socket?.send(utf8.encode(Protocol.joined), senderIp, senderPort);
      return;
    }

    // 2. Client Heartbeat Ping
    if (rawMessage == Protocol.ping) {
      _touchClient(clientId);
      _socket?.send(utf8.encode(Protocol.pong), senderIp, senderPort);
      return;
    }

    // 3. Client Leave Request
    if (rawMessage == Protocol.leave) {
      _removeClient(clientId);
      return;
    }

    // 4. Blind Broadcast (Group Forwarding)
    final roomId = _clientRooms[clientId];
    if (roomId != null && _rooms.containsKey(roomId)) {
      _touchClient(clientId);
      final roomClients = _rooms[roomId]!;

      for (final client in roomClients) {
        if (client.id != clientId) {
          _socket?.send(datagram.data, client.ip, client.port);
        }
      }
    }
  }

  void _touchClient(String clientId) {
    final roomId = _clientRooms[clientId];
    if (roomId != null && _rooms.containsKey(roomId)) {
      final match = _rooms[roomId]!.where((c) => c.id == clientId);
      if (match.isNotEmpty) {
        match.first.touch();
      }
    }
  }

  void _removeClient(String clientId) {
    final roomId = _clientRooms.remove(clientId);
    if (roomId != null && _rooms.containsKey(roomId)) {
      _rooms[roomId]!.removeWhere((c) => c.id == clientId);
      if (_rooms[roomId]!.isEmpty) {
        _rooms.remove(roomId);
      }
    }
  }

  void _startInactivityPruning() {
    _pruneTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final List<String> deadClients = [];

      _rooms.forEach((roomId, clients) {
        clients.removeWhere((client) {
          final isDead = client.isInactive(60);
          if (isDead) {
            deadClients.add(client.id);
          }
          return isDead;
        });
      });

      for (final id in deadClients) {
        _clientRooms.remove(id);
      }

      _rooms.removeWhere((roomId, clients) => clients.isEmpty);
    });
  }

  void _registerShutdownHooks() {
    void shutdown() {
      print('\nShutting down relay server...');
      _pruneTimer?.cancel();
      _socket?.close();
      exit(0);
    }

    ProcessSignal.sigint.watch().listen((_) => shutdown());
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) => shutdown());
    }
  }

  /// Resolves the desired port from CLI arguments or environment variables.
  static int resolvePort(List<String> args) {
    if (args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        if ((args[i] == '--port' || args[i] == '-p') && i + 1 < args.length) {
          final p = int.tryParse(args[i + 1]);
          if (p != null && p > 0 && p <= 65535) return p;
        }
      }
    }

    final envPort = int.tryParse(Platform.environment['PORT'] ?? '');
    if (envPort != null && envPort > 0 && envPort <= 65535) {
      return envPort;
    }

    return 443;
  }
}
