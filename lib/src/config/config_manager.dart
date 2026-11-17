import 'dart:convert';
import 'dart:io';

/// Manages local persistent configuration and command-line defaults.
class ConfigManager {
  static const String appVersion = '0.1.0';

  /// Built-in fallback relay (injected at build-time or defaults to official domain)
  static const String defaultRelayHost = String.fromEnvironment(
    'DEFAULT_RELAY',
    defaultValue: 'ipchatrelay.octetit.com',
  );

  static const int defaultRelayPort = int.fromEnvironment(
    'DEFAULT_PORT',
    defaultValue: 443,
  );

  /// Resolves the OS-specific path to the configuration file.
  static File getConfigFile() {
    String? configDir;
    if (Platform.isWindows) {
      configDir = Platform.environment['APPDATA'];
    } else {
      configDir = Platform.environment['XDG_CONFIG_HOME'];
      if (configDir == null || configDir.isEmpty) {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          configDir = '$home/.config';
        }
      }
    }
    configDir ??= Directory.systemTemp.path;
    final dir = Directory('$configDir/ipchat');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File('${dir.path}/config.json');
  }

  /// Loads configuration key-value pairs from disk.
  static Map<String, dynamic> load() {
    try {
      final file = getConfigFile();
      if (file.existsSync()) {
        final content = file.readAsStringSync().trim();
        if (content.isNotEmpty) {
          return jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return {};
  }

  /// Saves configuration key-value pairs to disk.
  static void save(Map<String, dynamic> config) {
    final file = getConfigFile();
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(config));
  }

  /// Sets and persists a custom relay server.
  static (String host, int port) setRelay(String target) {
    final (host, port) = parseHostAndPort(target, defaultRelayPort);
    final config = load();
    config['relay_host'] = host;
    config['relay_port'] = port;
    save(config);
    return (host, port);
  }

  /// Retrieves the saved custom relay server, if any.
  static (String host, int port)? getCustomRelay() {
    final config = load();
    final host = config['relay_host'] as String?;
    final port = config['relay_port'] as int?;
    if (host != null && host.isNotEmpty) {
      return (host, port ?? defaultRelayPort);
    }
    return null;
  }

  /// Clears any saved custom relay server from config.
  static void resetRelay() {
    final config = load();
    config.remove('relay_host');
    config.remove('relay_port');
    save(config);
  }

  /// Parses host and optional port from user strings like "domain.com", "1.2.3.4:8443", or "[::1]:443".
  static (String host, int port) parseHostAndPort(String input, [int defaultPort = 443]) {
    input = input.trim();
    if (input.startsWith('[') && input.contains(']')) {
      final closingIndex = input.indexOf(']');
      final host = input.substring(1, closingIndex);
      if (closingIndex + 1 < input.length && input[closingIndex + 1] == ':') {
        final port = int.tryParse(input.substring(closingIndex + 2)) ?? defaultPort;
        return (host, port);
      }
      return (host, defaultPort);
    }

    if (input.contains(':') && input.indexOf(':') == input.lastIndexOf(':')) {
      final parts = input.split(':');
      final host = parts[0];
      final port = int.tryParse(parts[1]) ?? defaultPort;
      return (host, port);
    }

    return (input, defaultPort);
  }
}
