import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_image_picker_demo/main.dart';

void main() {
  testWidgets('home page renders both demo entries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Flutter 学习 Demo'), findsOneWidget);
    expect(find.text('图片选择器 Demo'), findsOneWidget);
    expect(find.text('十万级图片列表 Demo'), findsOneWidget);
  });

  testWidgets('can open image picker demo from home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('图片选择器 Demo'));
    await tester.pumpAndSettle();

    expect(find.text('Flutter 图片选择器'), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    expect(find.text('从相册选择图片'), findsOneWidget);
  });
}
