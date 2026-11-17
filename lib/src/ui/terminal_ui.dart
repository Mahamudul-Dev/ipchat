import 'dart:io';
import 'dart:math';
import 'theme.dart';

/// Handles interactive terminal prompts, cursor controls, and styled output.
class TerminalUI {
  /// Displays the dynamic input prompt line.
  static void showPrompt() {
    final time = TerminalTheme.formatTime();
    stdout.write(
      '${TerminalTheme.bold}${TerminalTheme.primary}@You${TerminalTheme.reset} '
      '${TerminalTheme.dim}[$time]${TerminalTheme.reset} ❯ ',
    );
  }

  /// Prompts the user for a username. Defaults to Anon_XXXX if empty.
  static String promptUsername() {
    stdout.write(
      '${TerminalTheme.bold}${TerminalTheme.primary}? ${TerminalTheme.reset}'
      '${TerminalTheme.bold}Enter Username '
      '${TerminalTheme.system}(Leave blank for random)${TerminalTheme.reset}: ',
    );
    final input = stdin.readLineSync()?.trim() ?? '';
    if (input.isNotEmpty) return input;
    return 'Anon_${Random().nextInt(9999)}';
  }

  /// Prompts for secret password with terminal echo disabled.
  static String promptPassword() {
    stdout.write(
      '${TerminalTheme.bold}${TerminalTheme.primary}? ${TerminalTheme.reset}'
      '${TerminalTheme.bold}Enter Secret Room Password${TerminalTheme.reset}: ',
    );
    stdin.echoMode = false;
    final password = stdin.readLineSync()?.trim() ?? '';
    stdin.echoMode = true;
    print('\n');
    return password;
  }

  /// Renders an incoming chat message, clearing the current input prompt cleanly.
  static void renderIncomingMessage({
    required String sender,
    required String message,
    required String timestamp,
  }) {
    stdout.write(TerminalTheme.clearLine);
    print(
      '${TerminalTheme.bold}${TerminalTheme.friend}@$sender${TerminalTheme.reset} '
      '${TerminalTheme.dim}[$timestamp]${TerminalTheme.reset} ❯ $message',
    );
    showPrompt();
  }

  /// Renders your own outgoing message above the prompt.
  static void renderOwnMessage({
    required String message,
    required String timestamp,
  }) {
    stdout.write(TerminalTheme.moveUpOneLine);
    print(
      '${TerminalTheme.bold}${TerminalTheme.primary}@You${TerminalTheme.reset} '
      '${TerminalTheme.dim}[$timestamp]${TerminalTheme.reset} ❯ $message',
    );
    showPrompt();
  }

  /// Prints an informational system message.
  static void printSystem(String message) {
    print('${TerminalTheme.system}$message${TerminalTheme.reset}');
  }

  /// Prints a success message.
  static void printSuccess(String message) {
    print('${TerminalTheme.success}$message${TerminalTheme.reset}');
  }

  /// Prints an error message.
  static void printError(String message) {
    print('${TerminalTheme.error}$message${TerminalTheme.reset}');
  }

  /// Prints a warning message.
  static void printWarning(String message) {
    print('${TerminalTheme.warning}$message${TerminalTheme.reset}');
  }

  /// Prints a horizontal divider line.
  static void printDivider([int width = 50]) {
    print('${TerminalTheme.system}${'─' * width}${TerminalTheme.reset}\n');
  }
}
