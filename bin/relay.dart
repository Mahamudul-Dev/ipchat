import 'dart:io';
import 'dart:convert';

void main() async {
  const int port = 443; // Stealth Port
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
  print('🛡️ Zero-Knowledge Group Relay running on UDP $port...');

  // Map: RoomID -> List of Connected Clients
  final Map<String, List<_Client>> rooms = {};
  // Map: "IP:Port" -> RoomID (for fast lookup on incoming messages)
  final Map<String, String> clientRooms = {};

  socket.listen((RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = socket.receive();
      if (datagram == null) return;

      final senderIp = datagram.address;
      final senderPort = datagram.port;
      final clientId = '${senderIp.address}:$senderPort';
      final message = utf8.decode(datagram.data).trim();

      // Handle a client joining the room
      if (message.startsWith('[JOIN]')) {
        final roomId = message.split(' ')[1];
        rooms.putIfAbsent(roomId, () => []);

        final roomClients = rooms[roomId]!;
        final exists = roomClients.any((c) => c.id == clientId);

        if (!exists) {
          roomClients.add(_Client(senderIp, senderPort, clientId));
          clientRooms[clientId] = roomId;
        }

        // Acknowledge the connection immediately so the client can enter the chat
        socket.send(utf8.encode('[JOINED]'), senderIp, senderPort);
        return;
      }

      // Blind Forwarding (Group Broadcast)
      final roomId = clientRooms[clientId];
      if (roomId != null && rooms.containsKey(roomId)) {
        final roomClients = rooms[roomId]!;
        for (var client in roomClients) {
          // Forward the encrypted blob to everyone in the room EXCEPT the sender
          if (client.id != clientId) {
            socket.send(datagram.data, client.ip, client.port);
          }
        }
      }
    }
  });
}

class _Client {
  final InternetAddress ip;
  final int port;
  final String id;
  _Client(this.ip, this.port, this.id);
}
