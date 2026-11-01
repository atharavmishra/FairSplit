// Renders the app icon and splash PNGs into assets/icon/.
// Run: flutter test tool/render_icons_test.dart
// Then: dart run flutter_launcher_icons && dart run flutter_native_splash:create
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const teal = Color(0xFF1B998B);

/// The FairSplit mark: a coin split in two, one half brighter.
void paintMark(Canvas canvas, Offset c, double r) {
  final gap = r * 0.18;
  final rect = Rect.fromCircle(center: c, radius: r);
  Path half(double sweep) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..arcTo(rect, -pi / 2, sweep, false)
    ..close();

  canvas
    ..save()
    ..translate(-gap / 2, 0)
    ..drawPath(half(-pi), Paint()..color = Colors.white)
    ..restore()
    ..save()
    ..translate(gap / 2, 0)
    ..drawPath(half(pi), Paint()..color = Colors.white.withValues(alpha: 0.55))
    ..restore();
}

Future<void> render(String path, int size, {required double markRatio, Color? background}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (background != null) canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = background);
  paintMark(canvas, Offset(s / 2, s / 2), s * markRatio);
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('render icons', (tester) async {
    await tester.runAsync(() async {
      // Full icon (iOS, legacy Android): the mark fills ~60% of the square.
      await render('assets/icon/icon.png', 1024, markRatio: 0.30, background: teal);
      // Adaptive foreground: flutter_launcher_icons insets it 16% per side, so
      // this whole image already sits inside the safe zone.
      await render('assets/icon/foreground.png', 1024, markRatio: 0.32);
      // Splash: Android 12 shows a 1152px icon masked to its middle 768px circle.
      await render('assets/icon/splash.png', 1152, markRatio: 0.20);
    });
  });
}
