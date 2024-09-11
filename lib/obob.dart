import 'dart:io';
import 'dart:typed_data';
import 'package:html/dom.dart';
import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';

class Obob {
  static const String blogUrl = 'https://blog.naver.com/skfoodcompany';
  static const String rssUrl = 'https://rss.blog.naver.com/skfoodcompany.xml';
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
    if (await _isPostFromToday() && _messageSentTracker[_todayKey] == false) {
      await _processAndPostLunchMenu();
    }
  }

  Future<bool> _isPostFromToday() async {
    try {
      final response = await http.get(Uri.parse(rssUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load rss: ${response.statusCode}');
      }

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');
      if (items.isEmpty) throw Exception('No posts found');

      return _isToday(items.first);
    } catch (e) {
      stderr.writeln('Error checking latest post: $e');
      return false;
    }
  }

  bool _isToday(XmlElement post) {
    final pubDateString = post.findElements('pubDate').single.innerText;
    final pubDate =
        DateFormat("EEE, dd MMM yyyy HH:mm:ss Z", 'en_US').parse(pubDateString);
    final today = DateTime.now();

    return pubDate.year == today.year &&
        pubDate.month == today.month &&
        pubDate.day == today.day;
  }

  Future<void> _processAndPostLunchMenu() async {
    try {
      final iframeElement = await _getElements(url: blogUrl, tag: 'iframe');
      if (iframeElement == null) return;

      final src = iframeElement[0].attributes['src'];
      final fullSrc = Uri.parse(blogUrl).resolve(src!).toString();
      final imageElements =
          await _getElements(url: fullSrc, tag: 'img', isAll: true);
      if (imageElements == null) return;

      final images = await _getLunchImages(imageElements);
      if (images != null && images.isNotEmpty) {
        await _postImageToDiscord(images);
      }
    } catch (e) {
      stderr.writeln('Failed to process and post lunch menu: $e');
    }
  }

  Future<List<Element>?> _getElements(
      {required String url, required String tag, bool isAll = false}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load URL: ${response.statusCode}');
      }

      final document = parser.parse(response.body);
      if (isAll) {
        return document.querySelectorAll(tag);
      }

      final element = document.querySelector(tag);
      if (element == null) {
        throw Exception('Cannot find $tag');
      }
      return [element];
    } catch (e) {
      stderr.writeln('Error getting elements: $e');
      return null;
    }
  }

  Future<List<Uint8List>?> _getLunchImages(List<Element> elements) async {
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
  }

  Future<void> _postImageToDiscord(List<Uint8List> images) async {
    try {
      final channels = await Future.wait(
          _channelIds.map((id) => _bot.channels.fetch(Snowflake(id))));
      final textChannels = channels.whereType<GuildTextChannel>().toList();
      await Future.wait(
          textChannels.map((channel) => _sendImagesToChannel(channel, images)));
      _messageSentTracker[_todayKey] = true;
    } catch (e) {
      stderr.writeln('이미지 전송 중 오류 발생: $e');
    }
  }

  Future<void> _sendImagesToChannel(
      GuildTextChannel channel, List<Uint8List> images) async {
    await channel.sendMessage(MessageBuilder()
      ..attachments = images.asMap().entries.map((entry) {
        return AttachmentBuilder(
            data: entry.value, fileName: 'lunchmenu_${entry.key}.jpg');
      }).toList());
  }
}
