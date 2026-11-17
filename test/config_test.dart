import 'package:ipchat/ipchat.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigManager.parseHostAndPort', () {
    test('parses domain without port', () {
      final (host, port) = ConfigManager.parseHostAndPort('example.com', 443);
      expect(host, equals('example.com'));
      expect(port, equals(443));
    });

    test('parses domain with explicit port', () {
      final (host, port) = ConfigManager.parseHostAndPort('relay.example.com:8443', 443);
      expect(host, equals('relay.example.com'));
      expect(port, equals(8443));
    });

    test('parses IPv4 with port', () {
      final (host, port) = ConfigManager.parseHostAndPort('192.168.1.1:9000', 443);
      expect(host, equals('192.168.1.1'));
      expect(port, equals(9000));
    });

    test('parses IPv6 with bracket notation', () {
      final (host, port) = ConfigManager.parseHostAndPort('[2001:db8::1]:443', 443);
      expect(host, equals('2001:db8::1'));
      expect(port, equals(443));
    });
  });
}
