import 'package:ipchat/ipchat.dart';
import 'package:test/test.dart';

void main() {
  group('Protocol', () {
    test('builds join message correctly', () {
      expect(Protocol.buildJoin('room123'), equals('[JOIN] room123'));
    });

    test('extracts room ID from join message', () {
      expect(Protocol.extractRoomId('[JOIN] a1b2c3d4e5f60718'), equals('a1b2c3d4e5f60718'));
      expect(Protocol.extractRoomId('RANDOM_MESSAGE'), isNull);
    });

    test('detects system packets correctly', () {
      expect(Protocol.isSystemPacket('[PING]'), isTrue);
      expect(Protocol.isSystemPacket('[PONG]'), isTrue);
      expect(Protocol.isSystemPacket('[LEAVE]'), isTrue);
      expect(Protocol.isSystemPacket('CHAT_MESSAGE'), isFalse);
    });
  });
}
