import 'dart:io';
import 'package:bobjobot/obob.dart';

void main() async {
  final token = Platform.environment['DISCORD_BOT_TOKEN'];

  if (token == null) {
    stderr.writeln('토큰 찾을 수 없음');
    return;
  }

  final obob = Obob(token: token, channelIds: [1283369469275668504]);
  obob.activateBot();
}
