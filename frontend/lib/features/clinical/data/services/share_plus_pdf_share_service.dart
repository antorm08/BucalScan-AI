import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:bucalscan_ai/features/clinical/domain/services/pdf_share_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SharePlusPdfShareService implements PdfShareService {
  const SharePlusPdfShareService();

  @override
  Future<void> share(
    Uint8List bytes, {
    required String evaluationId,
    required ShareOrigin origin,
  }) async {
    final root = await getTemporaryDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}bucalscan-reports',
    );
    await directory.create(recursive: true);
    await _removeStaleReports(directory);
    final displayName = 'bucalscan-evaluacion-$evaluationId.pdf';
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'bucalscan-evaluacion-$evaluationId-'
      '${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    try {
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          fileNameOverrides: [displayName],
          subject: 'Informe de evaluación BucalScan AI',
          sharePositionOrigin: Rect.fromLTWH(
            origin.left,
            origin.top,
            origin.width,
            origin.height,
          ),
        ),
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _removeStaleReports(Directory directory) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.pdf')) continue;
      try {
        if ((await entity.lastModified()).isBefore(cutoff)) {
          await entity.delete();
        }
      } on FileSystemException {
        // A concurrent export may own the file; current-report cleanup still runs.
      }
    }
  }
}
