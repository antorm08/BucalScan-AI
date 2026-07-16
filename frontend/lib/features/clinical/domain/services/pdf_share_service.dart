import 'dart:typed_data';

class ShareOrigin {
  final double left;
  final double top;
  final double width;
  final double height;

  const ShareOrigin({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

abstract class PdfShareService {
  Future<void> share(
    Uint8List bytes, {
    required String evaluationId,
    required ShareOrigin origin,
  });
}
