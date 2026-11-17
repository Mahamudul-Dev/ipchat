import 'package:ipchat/ipchat.dart';
import 'package:test/test.dart';

void main() {
  group('ChatMessage', () {
    test('serializes to JSON correctly', () {
      final msg = ChatMessage(
        username: 'Alice',
        message: 'Hello World',
        timestamp: '14:30',
      );

      final json = msg.toJsonString();
      expect(json, contains('"u":"Alice"'));
      expect(json, contains('"m":"Hello World"'));
      expect(json, contains('"t":"14:30"'));
    });

    test('deserializes from valid JSON', () {
      const json = '{"u":"Bob","m":"Hey there!","t":"14:32"}';
      final msg = ChatMessage.fromJsonString(json);

      expect(msg, isNotNull);
      expect(msg!.username, equals('Bob'));
      expect(msg.message, equals('Hey there!'));
      expect(msg.timestamp, equals('14:32'));
    });

    test('returns null on invalid JSON', () {
      expect(ChatMessage.fromJsonString('not json'), isNull);
      expect(ChatMessage.fromJsonString('{"u":"Bob"}'), isNull); // Missing 'm'
    });
  });
}
