import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/feed_item.dart';

class FeedPage {
  const FeedPage({required this.total, required this.items});

  final int total;
  final List<FeedItem> items;
}

class FeedApi {
  const FeedApi({required this.baseUrl});

  final String baseUrl;

  Future<FeedPage> fetchItems({required int offset, required int limit}) async {
    final Uri uri = Uri.parse(baseUrl).replace(
      path: '/items',
      queryParameters: <String, String>{'offset': '$offset', 'limit': '$limit'},
    );

    final http.Response response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final Map<String, Object?> body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
    final List<Object?> rawItems = body['items'] as List<Object?>;

    return FeedPage(
      total: body['total'] as int,
      items: rawItems
          .cast<Map<String, Object?>>()
          .map(FeedItem.fromJson)
          .toList(growable: false),
    );
  }
}
