import 'dart:io';
import 'package:bobjobot/obob.dart';

void main() async {
  final token = Platform.environment['DISCORD_BOT_TOKEN'];

  if (token == null) {
    stderr.writeln('토큰을 찾을 수 없습니다.');
    return;
  }

  final obob = Obob(token: token, channelIds: [1230352884462260286]);

  try {
    await obob.activateBot();
    print('봇이 성공적으로 활성화되었습니다.');
  } catch (e) {
    stderr.writeln('봇 활성화 중 오류 발생: $e');
  }
}
