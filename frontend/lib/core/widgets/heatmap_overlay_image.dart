import 'package:flutter/material.dart';

class HeatmapOverlayImage extends StatelessWidget {
  final ImageProvider<Object> baseImage;
  final String? heatmapUrl;
  final BoxFit fit;
  final Widget? errorFallback;

  const HeatmapOverlayImage({
    super.key,
    required this.baseImage,
    this.heatmapUrl,
    this.fit = BoxFit.cover,
    this.errorFallback,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeatmap = heatmapUrl?.trim().isNotEmpty == true;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: baseImage,
          fit: fit,
          errorBuilder: (_, _, _) =>
              errorFallback ??
              const Center(child: Icon(Icons.broken_image_outlined)),
        ),
        if (hasHeatmap)
          Image.network(
            heatmapUrl!,
            key: const Key('camHeatmapOverlay'),
            fit: fit,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}
