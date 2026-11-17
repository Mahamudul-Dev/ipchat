/// Advanced ANSI color styling for terminal output.
class TerminalTheme {
  // Styles
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String clearScreen = '\x1B[2J\x1B[H';
  static const String clearLine = '\r\x1B[K';
  static const String moveUpOneLine = '\x1B[1A\x1B[K';

  // 256-Color Palette
  static const String primary = '\x1B[38;5;39m'; // Deep Sky Blue
  static const String success = '\x1B[38;5;46m'; // Neon Green
  static const String warning = '\x1B[38;5;220m'; // Gold
  static const String error = '\x1B[38;5;196m'; // Red
  static const String system = '\x1B[38;5;245m'; // Gray
  static const String friend = '\x1B[38;5;213m'; // Neon Pink

  /// Format a DateTime as HH:MM
  static String formatTime([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
