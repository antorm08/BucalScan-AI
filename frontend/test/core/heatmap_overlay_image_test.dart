import 'dart:convert';

import 'package:bucalscan_ai/core/widgets/heatmap_overlay_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders CAM overlay only when a URL is available', (
    tester,
  ) async {
    final transparentPixel = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 100,
          height: 100,
          child: HeatmapOverlayImage(
            baseImage: MemoryImage(transparentPixel),
            heatmapUrl: 'https://images.example.test/cam.png',
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('camHeatmapOverlay')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 100,
          height: 100,
          child: HeatmapOverlayImage(baseImage: MemoryImage(transparentPixel)),
        ),
      ),
    );

    expect(find.byKey(const Key('camHeatmapOverlay')), findsNothing);
  });
}
