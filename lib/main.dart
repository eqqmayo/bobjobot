import 'package:bobjobot/obob.dart';
import 'package:cron/cron.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final token = env['DISCORD_BOT_TOKEN'];

  if (token == null) {
    throw Exception('토큰 찾을 수 없음');
  }
  final cron = Cron();
  final obob = Obob(token: token, channelIds: [1277235797141098727]);

  cron.schedule(
      Schedule.parse('*/5 21-22 * * 3,4,5'), () => obob.activateBot());
  obob.activateBot();
}
