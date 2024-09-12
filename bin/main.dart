import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:bobjobot/obob.dart';
import 'package:shelf/shelf_io.dart';

void main() async {
  final token = Platform.environment['DISCORD_BOT_TOKEN'];

  if (token == null) {
    stderr.writeln('토큰을 찾을 수 없습니다.');
    return;
  }

  final obob = Obob(token: token, channelIds: [1283369469275668504]);

  var handler =
      const Pipeline().addMiddleware(logRequests()).addHandler((request) async {
    if (request.url.path == 'activate') {
      await obob.activateBot();
      return Response.ok('봇이 활성화되었습니다.');
    } else {
      return Response.notFound('페이지를 찾을 수 없습니다.');
    }
  });

  var server = await serve(handler, '0.0.0.0', 8080);
  stderr.writeln('서버 실행중: http://${server.address.host}:${server.port}');
}
