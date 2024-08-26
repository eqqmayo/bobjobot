import 'package:bobjobot/obob.dart';
import 'package:cron/cron.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load;
  final token = env['DISCORD_BOT_TOKEN'];

  if (token == null) {
    throw Exception('토큰 찾을 수 없음');
  }
  final cron = Cron();
  final obob = Obob(token: token, channelIds: []);

  cron.schedule(
      Schedule.parse('*/5 11-12 * * 3,4,5'), () => obob.activateBot());
}
