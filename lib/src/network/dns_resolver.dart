import 'dart:io';

/// Resolves hostnames or IP string representations to a valid [InternetAddress].
class DnsResolver {
  /// Resolves [host] into an [InternetAddress], preferring IPv4.
  static Future<InternetAddress> resolve(String host) async {
    final direct = InternetAddress.tryParse(host);
    if (direct != null) return direct;

    try {
      final results = await InternetAddress.lookup(host);
      final ipv4 = results.where((a) => a.type == InternetAddressType.IPv4);
      if (ipv4.isNotEmpty) return ipv4.first;
      if (results.isNotEmpty) return results.first;
    } catch (_) {}

    throw SocketException(
      'Failed to resolve relay host "$host". Please check your connection or server address.',
    );
  }
}
