import 'dart:typed_data';

enum PdfSaveResult { saved, cancelled }

abstract class PdfSaveService {
  Future<PdfSaveResult> save(Uint8List bytes, {required String evaluationId});
}
