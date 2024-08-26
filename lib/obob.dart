import 'dart:typed_data';

import 'package:html/dom.dart';
import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class Obob {
  static const String blogUrl = 'https://blog.naver.com/skfoodcompany';
  static const int maxImages = 10;

  final String token;
  late final NyxxGateway bot;
  final List<int> channelIds;
  final Map<String, bool> _messageSentTracker = {};

  Obob({required this.token, required this.channelIds}) {
    _initializeBot();
  }

  Future<void> _initializeBot() async {
    bot = await Nyxx.connectGateway(
      token,
      GatewayIntents.allUnprivileged,
    );
  }

  Future<void> activateBot() async {
    try {
      final iframeElement = await _getElements(url: blogUrl, tag: 'iframe');

      if (iframeElement != null) {
        final src = iframeElement.attributes['src'];
        final fullSrc = Uri.parse(blogUrl).resolve(src!).toString();
        final dateElement =
            await _getElements(url: fullSrc, tag: 'h3.se_textarea');

        if (dateElement != null) {
          final dateText = dateElement.text.trim();
          final images = await _getLunchImages(dateText, iframeElement);

          if (images != null) {
            await _postImageToDiscord(images);
          }
        }
      }
    } catch (e) {
      print('Failed to activateBot: $e');
    }
  }

  Future<void> _postImageToDiscord(List<Uint8List> images) async {
    try {
      final channels = await Future.wait(channelIds
          .map((id) async => await bot.channels.fetch(Snowflake(id))));

      for (var channel in channels) {
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
      }
    } catch (e) {
      print('이미지 전송 중 오류 발생: $e');
    }
  }

  Future<List<Uint8List>?> _getLunchImages(
      String dateText, Element element) async {
    if (_isToday(dateText)) {
      final todayKey = DateTime.now().toIso8601String().split('T')[0];

      if (_messageSentTracker[todayKey] != true) {
        final imageUrls = element
            .querySelectorAll('img')
            .map((img) => img.attributes['data-lazy-src'])
            .whereType<String>()
            .toList()
            .take(maxImages);

        final List<Uint8List> images = [];

        for (String imageUrl in imageUrls) {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            images.add(response.bodyBytes);
          } else {
            print('Failed to fetch image: $imageUrl');
          }
        }

        _messageSentTracker[todayKey] = true;
        return images;
      } else {
        print('오늘은 이미 알림을 완료하였습니다.');
      }
    }
    return null;
  }

  bool _isToday(String dateText) {
    DateTime today = DateTime.now();
    RegExp regExp = RegExp(r'(\d+)월(\d+)일');
    Match? match = regExp.firstMatch(dateText);

    return match != null &&
        int.parse(match[1]!) == today.month &&
        int.parse(match[2]!) == today.day;
  }

  Future<Element?> _getElements(
      {required String url, required String tag}) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      print('Failed to load url: ${response.statusCode}');
      return null;
    }

    final document = parser.parse(response.body);
    final element = document.querySelector(tag);

    if (element == null) {
      print('Cannot find $tag');
    }
    return element;
  }
}
