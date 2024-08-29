import 'dart:io';
import 'dart:typed_data';
import 'package:html/dom.dart';
import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class Obob {
  static const String blogUrl = 'https://blog.naver.com/skfoodcompany';
  static const int maxImages = 10;

  final String _token;
  final List<int> _channelIds;
  final Map<String, bool> _messageSentTracker = {};

  String get _todayKey => DateTime.now().toIso8601String().split('T')[0];

  late final NyxxGateway _bot;
  late Future<void> _initializationDone;

  Obob({
    required String token,
    required List<int> channelIds,
  })  : _token = token,
        _channelIds = channelIds {
    _initializationDone = _initializeBot();
  }

  Future<void> _initializeBot() async {
    _bot = await Nyxx.connectGateway(
      _token,
      GatewayIntents.allUnprivileged,
    );
  }

  Future<void> activateBot() async {
    await _initializationDone;

    try {
      final iframeElement = await _getElements(url: blogUrl, tag: 'iframe');

      if (iframeElement != null) {
        final src = iframeElement[0].attributes['src'];
        final fullSrc = Uri.parse(blogUrl).resolve(src!).toString();

        final imageElements =
            await _getElements(url: fullSrc, tag: 'img', isAll: true);
        final dateElement =
            await _getElements(url: fullSrc, tag: 'h3.se_textarea');

        if (imageElements != null && dateElement != null) {
          final dateText = dateElement[0].text.trim();
          final images = await _getLunchImages(dateText, imageElements);

          if (images != null && images.isNotEmpty) {
            await _postImageToDiscord(images);
          }
        }
      }
    } catch (e) {
      stderr.writeln('Failed to activateBot: $e');
    }
  }

  Future<void> _postImageToDiscord(List<Uint8List> images) async {
    try {
      final channels = await Future.wait(_channelIds
          .map((id) async => await _bot.channels.fetch(Snowflake(id))));

      for (var channel in channels) {
        if (channel is GuildTextChannel) {
          await channel.sendMessage(MessageBuilder()
            ..attachments = images
                .map((image) => AttachmentBuilder(
                    data: image,
                    fileName: 'lunchmenu_${images.indexOf(image)}.jpg'))
                .toList());

          _messageSentTracker[_todayKey] = true;
        } else {
          stderr.writeln('텍스트 채널이 아닙니다.');
        }
      }
    } catch (e) {
      stderr.writeln('이미지 전송 중 오류 발생: $e');
    }
  }

  Future<List<Uint8List>?> _getLunchImages(
      String dateText, List<Element> elements) async {
    if (_isToday(dateText)) {
      if (_messageSentTracker[_todayKey] != true) {
        final imageUrls = elements
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
            stderr.writeln('Failed to fetch image: $imageUrl');
          }
        }
        return images;
      } else {
        stderr.writeln('오늘은 이미 알림을 완료하였습니다.');
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

  Future<List<Element>?> _getElements(
      {required String url, required String tag, bool isAll = false}) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      stderr.writeln('Failed to load url: ${response.statusCode}');
      return null;
    }
    final document = parser.parse(response.body);
    if (isAll) {
      return document.querySelectorAll(tag);
    }
    final element = document.querySelector(tag);
    if (element != null) {
      return [element];
    }
    stderr.writeln('Cannot find $tag');
    return null;
  }
}
