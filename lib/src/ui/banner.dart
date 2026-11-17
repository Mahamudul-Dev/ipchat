import 'dart:io';
import 'theme.dart';

/// Renders the ASCII art header and banner.
class TerminalBanner {
  static void printHeader(String version) {
    stdout.write(TerminalTheme.clearScreen);
    print(
      r'''
$primary
    ____  ____  ________          __ 
   /  _/ / __ \/ ____/ /_  ____ _/ /_
   / /  / /_/ / /   / __ \/ __ `/ __/
 _/ /  / ____/ /___/ / / / /_/ / /_  
/___/ /_/    \____/_/ /_/\__,_/\__/  $dim v$version (E2EE)$reset
'''
          .replaceAll('\$primary', TerminalTheme.primary)
          .replaceAll('\$dim', TerminalTheme.dim)
          .replaceAll('\$reset', TerminalTheme.reset)
          .replaceAll('\$version', version),
    );

    print(
      '${TerminalTheme.system}${TerminalTheme.italic}'
      ' Secure Zero-Knowledge Ephemeral Group Chat '
      '${TerminalTheme.reset}\n',
    );
  }
}
