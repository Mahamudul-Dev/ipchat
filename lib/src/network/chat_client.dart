import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../crypto/chat_crypto.dart';
import '../models/chat_message.dart';
import '../protocol/protocol.dart';
import '../ui/terminal_ui.dart';
import '../ui/theme.dart';
import 'dns_resolver.dart';

/// Manages the UDP client socket, tunnel establishment, heartbeats, and message routing.
class ChatClient {
  final ChatCrypto crypto;
  final String username;
  final String relayHost;
  final int relayPort;

  RawDatagramSocket? _socket;
  Timer? _connectTimer;
  Timer? _keepAliveTimer;
  StreamSubscription? _stdinSubscription;
  bool _isConnected = false;

  ChatClient({
    required this.crypto,
    required this.username,
    required this.relayHost,
    required this.relayPort,
  });

  /// Starts the chat client, establishes the tunnel, and listens for terminal input.
  Future<void> start() async {
    TerminalUI.printSystem('⚙ Resolving relay ($relayHost:$relayPort)...');
    InternetAddress relayAddress;
    try {
      relayAddress = await DnsResolver.resolve(relayHost);
    } catch (e) {
      TerminalUI.printError(e.toString());
      exit(1);
    }

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      TerminalUI.printError('Failed to bind local UDP socket: $e');
      exit(1);
    }

    _registerSignalHandler(relayAddress);

    TerminalUI.printSystem(
      '⚙ Connecting to relay at ${relayAddress.address}:$relayPort...',
    );

    // 1. Connection Loop: Send [JOIN] <roomId> every second until acknowledged
    _connectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isConnected) {
        _socket?.send(
          utf8.encode(Protocol.buildJoin(crypto.roomId)),
          relayAddress,
          relayPort,
        );
      } else {
        timer.cancel();
      }
    });

    // 2. Incoming UDP Socket Listener
    _socket?.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket?.receive();
        if (datagram == null) return;

        final rawPayload = utf8.decode(datagram.data, allowMalformed: true).trim();

        if (rawPayload == Protocol.joined) {
          if (!_isConnected) {
            _isConnected = true;
            _connectTimer?.cancel();
            TerminalUI.printSuccess('✔ Connected to secure room! Listening for messages...\n');
            TerminalUI.printDivider();
            TerminalUI.showPrompt();

            // Start background UDP NAT keep-alive heartbeat
            _keepAliveTimer = Timer.periodic(const Duration(seconds: 20), (_) {
              if (_isConnected) {
                _socket?.send(utf8.encode(Protocol.ping), relayAddress, relayPort);
              }
            });
          }
        } else if (rawPayload == Protocol.pong || rawPayload == Protocol.ping) {
          // Internal keep-alive heartbeat, ignore
        } else if (_isConnected) {
          _handleIncomingPayload(rawPayload);
        }
      }
    });

    // 3. Stdin Terminal Input Listener
    _stdinSubscription = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String input) {
      final messageText = input.trim();
      if (messageText.isNotEmpty && _isConnected) {
        final now = TerminalTheme.formatTime();
        TerminalUI.renderOwnMessage(message: messageText, timestamp: now);

        final message = ChatMessage(
          username: username,
          message: messageText,
          timestamp: now,
        );

        final encryptedTransmission = crypto.encrypt(message.toJsonString());
        _socket?.send(
          utf8.encode(encryptedTransmission),
          relayAddress,
          relayPort,
        );
      }

      if (_isConnected) {
        TerminalUI.showPrompt();
      }
    });
  }

  void _handleIncomingPayload(String payload) {
    final decryptedJson = crypto.decrypt(payload);
    if (decryptedJson == null) return;

    final message = ChatMessage.fromJsonString(decryptedJson);
    if (message == null) return;

    TerminalUI.renderIncomingMessage(
      sender: message.username,
      message: message.message,
      timestamp: message.timestamp,
    );
  }

  void _registerSignalHandler(InternetAddress relayAddress) {
    ProcessSignal.sigint.watch().listen((_) {
      TerminalUI.printWarning('\n\n⚠ Erasing session from memory and disconnecting... Bye!');
      try {
        _socket?.send(utf8.encode(Protocol.leave), relayAddress, relayPort);
      } catch (_) {}
      disconnect();
      exit(0);
    });
  }

  /// Closes socket and cancels timers.
  void disconnect() {
    _connectTimer?.cancel();
    _keepAliveTimer?.cancel();
    _stdinSubscription?.cancel();
    _socket?.close();
    _isConnected = false;
  }
}
