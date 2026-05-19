import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as image;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

const int totalItems = 100000;
const int maxPageSize = 100;

final Random _random = Random();
final Map<int, List<int>> _imageCache = <int, List<int>>{};

Future<void> main(List<String> args) async {
  final int port = args.isNotEmpty ? int.parse(args.first) : 8080;
  final Router router = Router()
    ..get('/items', _itemsHandler)
    ..get('/images/<id>.png', _imageHandler)
    ..options('/<ignored|.*>', _optionsHandler);

  final Handler handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  final HttpServer server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    port,
  );

  stdout.writeln('Image server listening on http://localhost:${server.port}');
  stdout.writeln('Android emulator should use http://10.0.2.2:${server.port}');
}

Response _itemsHandler(Request request) {
  final int offset = _intQuery(request, 'offset', 0).clamp(0, totalItems);
  final int limit = _intQuery(request, 'limit', 30).clamp(1, maxPageSize);
  final int end = min(offset + limit, totalItems);
  final String origin =
      '${request.requestedUri.scheme}://'
      '${request.requestedUri.authority}';

  final List<Map<String, Object>> items = <Map<String, Object>>[
    for (int id = offset; id < end; id++)
      <String, Object>{
        'id': id,
        'title': '聊天对象 #$id',
        'subtitle': '这是一条按需加载的列表消息，图片有随机延迟。',
        'imageUrl': '$origin/images/$id.png',
      },
  ];

  return Response.ok(
    jsonEncode(<String, Object>{
      'total': totalItems,
      'offset': offset,
      'limit': limit,
      'items': items,
    }),
    headers: <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    },
  );
}

Future<Response> _imageHandler(Request request, String id) async {
  final int imageId = int.tryParse(id) ?? 0;
  final int delayMs = 500 + _random.nextInt(501);
  await Future<void>.delayed(Duration(milliseconds: delayMs));

  final List<int> pngBytes = _imageCache.putIfAbsent(
    imageId,
    () => _generateImage(imageId),
  );

  return Response.ok(
    pngBytes,
    headers: <String, String>{
      HttpHeaders.contentTypeHeader: 'image/png',
      HttpHeaders.cacheControlHeader: 'public, max-age=3600',
    },
  );
}

Response _optionsHandler(Request request, String ignored) {
  return Response.ok('');
}

int _intQuery(Request request, String name, int fallback) {
  final String? raw = request.url.queryParameters[name];
  if (raw == null) {
    return fallback;
  }
  return int.tryParse(raw) ?? fallback;
}

List<int> _generateImage(int id) {
  const int size = 128;
  final image.Image canvas = image.Image(width: size, height: size);

  final int baseHue = (id * 37) % 360;
  final image.ColorRgb8 primary = _hslToRgb(baseHue, 0.64, 0.58);
  final image.ColorRgb8 secondary = _hslToRgb((baseHue + 65) % 360, 0.72, 0.46);

  image.fill(canvas, color: primary);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      if ((x + y + id) % 17 < 8) {
        canvas.setPixel(x, y, secondary);
      }
    }
  }

  image.fillCircle(
    canvas,
    x: size ~/ 2,
    y: size ~/ 2,
    radius: 34,
    color: image.ColorRgb8(255, 255, 255),
  );
  image.fillCircle(
    canvas,
    x: size ~/ 2,
    y: size ~/ 2,
    radius: 28,
    color: primary,
  );

  return image.encodePng(canvas, level: 1);
}

image.ColorRgb8 _hslToRgb(int hue, double saturation, double lightness) {
  final double c = (1 - (2 * lightness - 1).abs()) * saturation;
  final double x = c * (1 - ((hue / 60) % 2 - 1).abs());
  final double m = lightness - c / 2;

  final (double red, double green, double blue) = switch (hue ~/ 60) {
    0 => (c, x, 0),
    1 => (x, c, 0),
    2 => (0, c, x),
    3 => (0, x, c),
    4 => (x, 0, c),
    _ => (c, 0, x),
  };

  return image.ColorRgb8(
    ((red + m) * 255).round(),
    ((green + m) * 255).round(),
    ((blue + m) * 255).round(),
  );
}

Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final Response response = await innerHandler(request);
      return response.change(
        headers: <String, String>{
          ...response.headers,
          HttpHeaders.accessControlAllowOriginHeader: '*',
          HttpHeaders.accessControlAllowMethodsHeader: 'GET, OPTIONS',
          HttpHeaders.accessControlAllowHeadersHeader: 'Origin, Content-Type',
        },
      );
    };
  };
}
