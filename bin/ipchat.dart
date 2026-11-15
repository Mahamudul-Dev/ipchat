import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

const String vpsIp = '157.173.115.123';
const int vpsPort = 443;

// --- Advanced ANSI Styling ---
const String reset = '\x1B[0m';
const String bold = '\x1B[1m';
const String dim = '\x1B[2m';
const String italic = '\x1B[3m';
const String clearScreen = '\x1B[2J\x1B[H';

// 256-Color Palette
const String primary = '\x1B[38;5;39m'; // Deep Sky Blue
const String success = '\x1B[38;5;46m'; // Neon Green
const String warning = '\x1B[38;5;220m'; // Gold
const String error = '\x1B[38;5;196m'; // Red
const String system = '\x1B[38;5;245m'; // Gray
const String friendCol = '\x1B[38;5;213m'; // Neon Pink

// Helper to get current time (e.g., 15:14)
String get _time {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}

// Dynamic Input Prompt
void _showPrompt() {
  stdout.write('$bold$primary@You$reset $dim[$_time]$reset ❯ ');
}

void main() async {
  // Clear the terminal and print the banner
  stdout.write(clearScreen);
  print(
    r'''
$primary
    ____  ____  ________          __ 
   /  _/ / __ \/ ____/ /_  ____ _/ /_
   / /  / /_/ / /   / __ \/ __ `/ __/
 _/ /  / ____/ /___/ / / / /_/ / /_  
/___/ /_/    \____/_/ /_/\__,_/\__/  $dim v3.0 (E2EE)$reset
'''
        .replaceAll('\$primary', primary)
        .replaceAll('\$dim', dim)
        .replaceAll('\$reset', reset),
  );

  print('$system$italic Secure Zero-Knowledge P2P Tunnel $reset\n');

  // 1. Username Assignment
  stdout.write(
    '$bold$primary? $reset$bold Enter Username $system(Leave blank for random)$reset: ',
  );
  String username = stdin.readLineSync()?.trim() ?? '';
  if (username.isEmpty) {
    username = 'Anon_${Random().nextInt(9999)}';
  }

  // 2. Room & Crypto Setup
  stdout.write('$bold$primary? $reset$bold Enter Secret Room Password$reset: ');
  stdin.echoMode = false;
  final password = stdin.readLineSync()?.trim() ?? '';
  stdin.echoMode = true;
  print('\n');

  if (password.length < 6) {
    print('\n$error✖ Password too short. Use at least 6 characters.$reset');
    exit(1);
  }

  final keyBytes = sha256.convert(utf8.encode(password)).bytes;
  final key = enc.Key(Uint8List.fromList(keyBytes));
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
  final roomId = sha256.convert(keyBytes).toString().substring(0, 16);

  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  bool isConnected = false;

  ProcessSignal.sigint.watch().listen((signal) {
    print('\n\n$warning⚠ Erasing session and closing port... Bye!$reset');
    socket.close();
    exit(0);
  });

  print('$system⚙ Establishing encrypted tunnel to relay...$reset');

  // 3. Connect to Relay
  Timer.periodic(Duration(seconds: 1), (timer) {
    if (!isConnected) {
      socket.send(
        utf8.encode('[JOIN] $roomId'),
        InternetAddress(vpsIp),
        vpsPort,
      );
    } else {
      timer.cancel();
    }
  });

  // 4. Handle Incoming Group Traffic
  socket.listen((RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = socket.receive();
      if (datagram == null) return;

      final payload = utf8.decode(datagram.data).trim();

      if (payload == '[JOINED]') {
        if (!isConnected) {
          isConnected = true;
          print(
            '$success✔ Connected to secure room! Listening for messages...$reset\n',
          );
          print('$system${'─' * 50}$reset\n');
          _showPrompt();
        }
      } else if (isConnected) {
        try {
          // Decrypt payload
          final iv = enc.IV.fromBase64(payload.substring(0, 24));
          final encryptedText = enc.Encrypted.fromBase64(payload.substring(24));
          final decrypted = encrypter.decrypt(encryptedText, iv: iv);

          final data = jsonDecode(decrypted);
          final sender = data['u'];
          final msg = data['m'];
          final time = data['t'] ?? _time;

          // Clear current typing line to render incoming message cleanly
          stdout.write('\r\x1B[K');
          print('$bold$friendCol@$sender$reset $dim[$time]$reset ❯ $msg');
          _showPrompt();
        } catch (e) {
          // Ignore hijacked/corrupted packets
        }
      }
    }
  });

  // 5. Handle Outgoing Group Traffic
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((
    String input,
  ) {
    final message = input.trim();
    if (message.isNotEmpty && isConnected) {
      // Move cursor up one line and clear it so our own message doesn't double-print uglily
      stdout.write('\x1B[1A\x1B[K');
      print('$bold$primary@You$reset $dim[$_time]$reset ❯ $message');

      final payloadData = jsonEncode({
        'u': username,
        'm': message,
        't': _time, // Send timestamp so friends see exactly when you sent it
      });

      final iv = enc.IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(payloadData, iv: iv);

      final transmission = iv.base64 + encrypted.base64;
      socket.send(utf8.encode(transmission), InternetAddress(vpsIp), vpsPort);
    }

    if (isConnected) _showPrompt();
  });
}
