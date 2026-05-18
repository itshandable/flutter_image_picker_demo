import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_image_picker_demo/main.dart';

void main() {
  testWidgets('image picker home renders initial state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Flutter 图片选择器'), findsOneWidget);
    expect(find.text('还没有选择图片'), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    expect(find.text('从相册选择图片'), findsOneWidget);
  });
}
