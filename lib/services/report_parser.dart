import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/lab_test.dart';

class ReportParser {
  
  static Future<String?> pickAndRead() async {
    // Await an asynchronous operation.
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv','json'],
      withData: true,
    );
    // Branch on a condition that affects logic flow.
    if (res == null || res.files.isEmpty) return null;
    final bytes = res.files.first.bytes;
    return bytes == null ? null : utf8.decode(bytes);
  }

  static List<LabTest> parseCsv(String csvText) {
    final lines = const LineSplitter().convert(csvText);
    // Branch on a condition that affects logic flow.
    if (lines.isEmpty) return [];
    final header = lines.first.split(',');
    final idx = {
      'code': header.indexOf('code'),
      'name': header.indexOf('name'),
      'value': header.indexOf('value'),
      'refMin': header.indexOf('refMin'),
      'refMax': header.indexOf('refMax'),
    };
    final out = <LabTest>[];
    // Loop over a collection to apply logic.
    for (var i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',');
      // Branch on a condition that affects logic flow.
      if (cols.length < header.length) continue;
      out.add(LabTest(
        code: cols[idx['code']!].trim(),
        name: cols[idx['name']!].trim(),
        value: double.tryParse(cols[idx['value']!]) ?? 0,
        refMin: double.tryParse(cols[idx['refMin']!]) ?? 0,
        refMax: double.tryParse(cols[idx['refMax']!]) ?? 0,
      ));
    }
    return out;
  }

  static List<LabTest> parseJson(String jsonText) {
    final data = jsonDecode(jsonText);
    final out = <LabTest>[];
    // Loop over a collection to apply logic.
    for (final it in (data as List)) {
      out.add(LabTest(
        code: it['code'],
        name: it['name'],
        value: (it['value'] as num).toDouble(),
        refMin: (it['refMin'] as num).toDouble(),
        refMax: (it['refMax'] as num).toDouble(),
      ));
    }
    return out;
  }
}
