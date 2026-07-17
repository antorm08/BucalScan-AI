import 'dart:typed_data';

import 'package:bucalscan_ai/features/clinical/domain/services/pdf_save_service.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerPdfSaveService implements PdfSaveService {
  const FilePickerPdfSaveService();

  @override
  Future<PdfSaveResult> save(
    Uint8List bytes, {
    required String evaluationId,
  }) async {
    final safeId = evaluationId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar informe de evaluación',
      fileName: 'bucalscan-evaluacion-$safeId.pdf',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
    return path == null ? PdfSaveResult.cancelled : PdfSaveResult.saved;
  }
}
