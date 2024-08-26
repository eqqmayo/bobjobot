import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:nyxx/nyxx.dart';
import 'package:cron/cron.dart';

Map<String, bool> messageSentTracker = {};
void main() async {
  final bot = await Nyxx.connectGateway(
    '<Token>',
    GatewayIntents.allUnprivileged,
  );
  final cron = Cron();
  cron.schedule(
      Schedule.parse('*/5 11-12 * * 3,4,5'), () => checkBlogAndPostImages(bot));
}

Future<void> checkBlogAndPostImages(NyxxGateway bot) async {
  final blogUrl = 'https://blog.naver.com/skfoodcompany';
  final response = await http.get(Uri.parse(blogUrl));

  if (response.statusCode == 200) {
    final doc = parser.parse(response.body);
    final iframe = doc.querySelector('iframe');

    if (iframe != null) {
      final src = iframe.attributes['src'];
      final fullSrc = Uri.parse(blogUrl).resolve(src!).toString();

      final iframeResponse = await http.get(Uri.parse(fullSrc));

      if (iframeResponse.statusCode == 200) {
        final iframeDoc = parser.parse(iframeResponse.body);

        var dateElement = iframeDoc.querySelector('h3.se_textarea')!;

        String dateText = dateElement.text.trim();
        if (isToday(dateText)) {
          String todayKey = DateTime.now().toIso8601String().split('T')[0];

          if (messageSentTracker[todayKey] != true) {
            final imageUrls = iframeDoc
                .querySelectorAll('img')
                .map((img) => img.attributes['data-lazy-src'])
                .whereType<String>()
                .toList()
                .take(10);

            final List<Uint8List> images = [];
            for (String imageUrl in imageUrls) {
              images.add((await http.get(Uri.parse(imageUrl))).bodyBytes);
            }

            await postImageToDiscord(bot, images);
            messageSentTracker[todayKey] = true;
          } else {
            print('오늘은 이미 메시지를 보냈습니다.');
          }
        }
      } else {
        print('iframe content 로드 실패: ${iframeResponse.statusCode}');
      }
    } else {
      print('iframe 찾을 수 없음');
    }
  } else {
    print('Blog load 실패: ${response.statusCode}');
  }
}

Future<void> postImageToDiscord(NyxxGateway bot, List<Uint8List> images) async {
  try {
    final channel = await bot.channels.fetch(Snowflake(1277235797141098727));

    if (channel is GuildTextChannel) {
      await channel.sendMessage(MessageBuilder()
        ..attachments = images
            .map((image) => AttachmentBuilder(
                data: image,
                fileName: 'lunchmenu_${images.indexOf(image)}.jpg'))
            .toList());
    } else {
      print('텍스트 채널이 아닙니다.');
    }
  } catch (e) {
    print('이미지 전송 중 오류 발생: $e');
  }
}

bool isToday(String text) {
  DateTime today = DateTime.now();

  RegExp regExp = RegExp(r'(\d+)월(\d+)일');
  Match? match = regExp.firstMatch(text);

  if (match != null) {
    int month = int.parse(match[1]!);
    int day = int.parse(match[2]!);

    if (month == today.month && day == today.day) {
      return true;
    }
  }
  return false;
}
