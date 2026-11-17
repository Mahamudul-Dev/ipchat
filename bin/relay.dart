import 'package:ipchat/ipchat.dart';

void main(List<String> args) async {
  final port = RelayServer.resolvePort(args);
  final server = RelayServer(port: port);
  await server.start();
}
