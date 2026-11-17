import 'dart:io';

import 'package:args/args.dart';
import 'package:ipchat/ipchat.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('relay', abbr: 'r', help: 'Relay server IP or domain for this session.')
    ..addOption('port', abbr: 'p', help: 'Relay UDP port for this session.')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage instructions.')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show IPChat version.');

  ArgResults parsedArgs;
  try {
    parsedArgs = parser.parse(args);
  } catch (e) {
    TerminalUI.printError('✖ Error: ${e.toString()}');
    print('Run ${TerminalTheme.bold}ipchat --help${TerminalTheme.reset} for usage details.');
    exit(1);
  }

  if (parsedArgs['help'] as bool) {
    _printHelp(parser);
    exit(0);
  }

  if (parsedArgs['version'] as bool) {
    print('${TerminalTheme.bold}IPChat${TerminalTheme.reset} version ${ConfigManager.appVersion}');
    exit(0);
  }

  // Handle Subcommands: set-relay, get-relay, reset-relay
  final rest = parsedArgs.rest;
  if (rest.isNotEmpty) {
    _handleSubcommand(rest);
    return;
  }

  // Determine active relay endpoint:
  // Precedence: 1. CLI flag -> 2. Saved Config -> 3. Built-in default
  String activeHost = '';
  int activePort = ConfigManager.defaultRelayPort;

  if (parsedArgs['relay'] != null) {
    final (h, p) = ConfigManager.parseHostAndPort(
      parsedArgs['relay'] as String,
      ConfigManager.defaultRelayPort,
    );
    activeHost = h;
    activePort = p;
  } else {
    final customRelay = ConfigManager.getCustomRelay();
    if (customRelay != null) {
      activeHost = customRelay.$1;
      activePort = customRelay.$2;
    } else if (ConfigManager.defaultRelayHost.isNotEmpty) {
      activeHost = ConfigManager.defaultRelayHost;
      activePort = ConfigManager.defaultRelayPort;
    }
  }

  if (parsedArgs['port'] != null) {
    final parsedPort = int.tryParse(parsedArgs['port'] as String);
    if (parsedPort != null && parsedPort > 0 && parsedPort <= 65535) {
      activePort = parsedPort;
    }
  }

  // Render header & banner
  TerminalBanner.printHeader(ConfigManager.appVersion);

  // Fallback prompt if no host is configured at all
  if (activeHost.isEmpty) {
    stdout.write(
      '${TerminalTheme.bold}${TerminalTheme.primary}? ${TerminalTheme.reset}'
      '${TerminalTheme.bold}Enter Relay Server IP or Domain${TerminalTheme.reset}: ',
    );
    activeHost = stdin.readLineSync()?.trim() ?? '';
    if (activeHost.isEmpty) {
      TerminalUI.printError('✖ Relay server cannot be empty.');
      exit(1);
    }
    final (h, p) = ConfigManager.parseHostAndPort(activeHost, ConfigManager.defaultRelayPort);
    activeHost = h;
    activePort = p;
  }

  // Prompt user details
  final username = TerminalUI.promptUsername();
  final password = TerminalUI.promptPassword();

  ChatCrypto crypto;
  try {
    crypto = ChatCrypto.fromPassword(password);
  } catch (e) {
    TerminalUI.printError(e.toString());
    exit(1);
  }

  // Start chat client tunnel
  final client = ChatClient(
    crypto: crypto,
    username: username,
    relayHost: activeHost,
    relayPort: activePort,
  );

  await client.start();
}

void _handleSubcommand(List<String> rest) {
  final command = rest.first.toLowerCase();

  if (command == 'set-relay') {
    if (rest.length < 2) {
      TerminalUI.printError('✖ Error: Please provide a server address.');
      print('Example: ${TerminalTheme.bold}ipchat set-relay my-relay.example.com${TerminalTheme.reset}');
      print('         ${TerminalTheme.bold}ipchat set-relay 1.2.3.4:443${TerminalTheme.reset}');
      exit(1);
    }
    final (host, port) = ConfigManager.setRelay(rest[1]);
    TerminalUI.printSuccess('✔ Registered custom relay server: ${TerminalTheme.bold}$host:$port');
    TerminalUI.printSystem('Saved to: ${ConfigManager.getConfigFile().path}');
    exit(0);
  }

  if (command == 'get-relay') {
    final custom = ConfigManager.getCustomRelay();
    if (custom != null) {
      print(
        '${TerminalTheme.bold}Custom Relay:${TerminalTheme.reset} ${custom.$1}:${custom.$2} '
        '${TerminalTheme.system}(from ${ConfigManager.getConfigFile().path})${TerminalTheme.reset}',
      );
    } else {
      print(
        '${TerminalTheme.bold}Default Relay:${TerminalTheme.reset} '
        '${ConfigManager.defaultRelayHost}:${ConfigManager.defaultRelayPort} '
        '${TerminalTheme.system}(Official)${TerminalTheme.reset}',
      );
    }
    exit(0);
  }

  if (command == 'reset-relay') {
    ConfigManager.resetRelay();
    TerminalUI.printSuccess(
      '✔ Reset relay configuration to official default: '
      '${TerminalTheme.bold}${ConfigManager.defaultRelayHost}:${ConfigManager.defaultRelayPort}',
    );
    exit(0);
  }

  TerminalUI.printError('✖ Unknown command: $command');
  print('Run ${TerminalTheme.bold}ipchat --help${TerminalTheme.reset} for usage details.');
  exit(1);
}

void _printHelp(ArgParser parser) {
  print('''
${TerminalTheme.bold}IPChat${TerminalTheme.reset} - Secure, Anonymous, Zero-Knowledge Terminal E2EE Chat

${TerminalTheme.bold}USAGE:${TerminalTheme.reset}
  ipchat [options]
  ipchat <command>

${TerminalTheme.bold}COMMANDS:${TerminalTheme.reset}
  ${TerminalTheme.bold}set-relay <host[:port]>${TerminalTheme.reset}    Register a self-hosted relay server permanently
  ${TerminalTheme.bold}get-relay${TerminalTheme.reset}                 Show the currently configured relay server
  ${TerminalTheme.bold}reset-relay${TerminalTheme.reset}               Reset to the official default relay server

${TerminalTheme.bold}OPTIONS:${TerminalTheme.reset}
${parser.usage}

${TerminalTheme.bold}EXAMPLES:${TerminalTheme.reset}
  # Start chat with default or configured relay:
  ipchat

  # Save a self-hosted relay permanently:
  ipchat set-relay my-relay.example.com
  ipchat set-relay 157.173.115.123:443

  # Connect to a relay for just one session:
  ipchat --relay 157.173.115.123 --port 443
''');
}
