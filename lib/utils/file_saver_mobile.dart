import 'dart:convert';
import 'dart:typed_data';
import 'package:printing/printing.dart';

void saveFile(String content, String fileName) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  await Printing.sharePdf(
    bytes: bytes,
    filename: fileName,
  );
}

void saveBytes(List<int> bytes, String fileName) async {
  await Printing.sharePdf(
    bytes: Uint8List.fromList(bytes),
    filename: fileName,
  );
}
