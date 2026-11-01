// Renders the Play Store icon and feature graphic into store/.
// Run: flutter test tool/render_store_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'render_icons_test.dart' show paintMark, render, teal;

/// Roboto ships with the Flutter SDK; tests otherwise draw text in a box font.
Future<void> loadRoboto() async {
  final fonts = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final weight in ['Regular', 'Bold']) {
    final bytes = File('$fonts/Roboto-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void drawText(Canvas canvas, String text, Offset at, double size, FontWeight weight, Color color) {
  TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: weight, color: color),
    ),
    textDirection: TextDirection.ltr,
  )
    ..layout()
    ..paint(canvas, at);
}

Future<void> renderFeatureGraphic(String path) async {
  const w = 1024, h = 500;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1024, 500), Paint()..color = teal);
  // Play crops edges on some surfaces; everything stays well inside the frame.
  paintMark(canvas, const Offset(250, 250), 120);
  drawText(canvas, 'FairSplit', const Offset(430, 150), 92, FontWeight.bold, Colors.white);
  drawText(canvas, 'Split expenses with friends.', const Offset(434, 268), 38, FontWeight.normal,
      Colors.white);
  drawText(canvas, 'Free, no limits, no ads.', const Offset(434, 318), 38, FontWeight.normal,
      Colors.white.withValues(alpha: 0.8));
  final image = await recorder.endRecording().toImage(w, h);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('render store assets', (tester) async {
    await tester.runAsync(() async {
      await loadRoboto();
      // Play masks the 512px icon itself; supply a full square.
      await render('store/icon-512.png', 512, markRatio: 0.30, background: teal);
      await renderFeatureGraphic('store/feature-graphic.png');
    });
  });
}
