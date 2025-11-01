// services/pdf_extractor.dart
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';
import '../models/lab_test.dart';
import 'term_dictionary.dart';

class PdfExtractor {
  static Future<List<LabTest>> parse(String pdfPath) async {
    final bytes = await File(pdfPath).readAsBytes();
    return _parseBytes(Uint8List.fromList(bytes));
  }

  static Future<List<LabTest>> parseAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return _parseBytes(data.buffer.asUint8List());
  }

  static Future<List<LabTest>> _parseBytes(Uint8List bytes) async {
    final doc = PdfDocument(inputBytes: bytes);
    final ext = PdfTextExtractor(doc);

    // نحتاج نمط عام للصف: name  value  ...  refmin - refmax
    final rowRe = RegExp(
      r'(?<name>[A-Za-z][A-Za-z0-9 /()\-\+:%\.]*?)\s*'   // الاسم (كسول)
      r'(?<value>-?\d+(?:\.\d+)?)\s*'                    // القيمة الأولى بعد الاسم
      r'(?:[^\n]{0,80}?)'                                // اسمحي بأي نص (حتى لو فيه أرقام) قبل الرينج
      r'(?<refmin>-?\d+(?:\.\d+)?)\s*[-–]\s*(?<refmax>-?\d+(?:\.\d+)?)',
      caseSensitive: false,
      dotAll: true,
    );

    const unitPattern =
        r'(?:10\^\d+\/[A-Za-z]+|g\/dL|mg\/dL|mmol\/L|µ?mol\/L|ng\/mL|IU\/L|U\/L|fL|pg|%|10\^9\/L|10\^3\/µL|cells\/µL|K\/µL|x10\^\d+\/u?l)';

    final tests = <LabTest>[];

    for (int i = 0; i < doc.pages.count; i++) {
      var text = ext.extractText(startPageIndex: i, endPageIndex: i);
      debugPrint('[PDF] page $i chars=${text.length}');

      // Normalize
      text = text
          .replaceAll('\r', ' ')
          .replaceAll('\t', ' ')
          .replaceAll('\u200f', ' ')
          .replaceAll('\u200e', ' ')
          .replaceAll('–', '-');

      // احذف التواريخ/الأوقات (AM/PM) التي تلخبط
      final dateTimeRe = RegExp(
        r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b(?:\s+\d{1,2}:\d{2}\s?(?:AM|PM))?',
        caseSensitive: false,
      );
      text = text.replaceAll(dateTimeRe, ' ');

      // أضف مسافة إذا الوحدة ملتصقة بالقيمة: mg/dL3.33 → mg/dL 3.33
      text = text.replaceAllMapped(
        RegExp('($unitPattern)(?=\\d)', caseSensitive: false),
        (m) => '${m[0]} ',
      );

      // أضف مسافة إذا كان هناك حرف/قوس يسبق رقم مباشرة: count4.72 → count 4.72
      text = text.replaceAllMapped(
        RegExp(r'([A-Za-z\)])(?=\d)'),
        (m) => '${m[1]} ',
      );

      // فك التصاق أرقام القيمة بالرينج: 318180 - 1100 → 318 180 - 1100
      text = text.replaceAllMapped(
        RegExp(r'(\d{2,})(?=\d{2,}\s*-\s*\d)'),
        (m) => '${m[1]} ',
      );

      // فضّي المسافات المكررة
      text = text.replaceAllMapped(RegExp(r'[ ]{2,}'), (m) => ' ');

      final matches = rowRe.allMatches(text).toList();
      debugPrint('[PDF] page $i found rows=${matches.length}');

      for (final m in matches) {
        final rawName = (m.namedGroup('name') ?? '').trim();
        final valStr  = (m.namedGroup('value') ?? '').trim();
        final loStr   = (m.namedGroup('refmin') ?? '').trim();
        final hiStr   = (m.namedGroup('refmax') ?? '').trim();

        // استبعاد أسماء ليست تحاليل
        final badName = RegExp(
          r'^(?:Patient\s*Name|Gender|Age|Visit\s*Number|Result|Reference\s*Range|Refrence\s*Range|Unit|Registered|Authenticated|Printed|\(AM\)|\(PM\)|AM|PM|Branch\s*Name|Patient ID)$',
          caseSensitive: false,
        );
        if (badName.hasMatch(rawName)) continue;

        // إذا لازالت القيمة ملتصقة بذيل الاسم لأي سبب، قصّيها
        var fixedName = rawName;
        if (valStr.isNotEmpty &&
            fixedName.toLowerCase().endsWith(valStr.toLowerCase())) {
          fixedName =
              fixedName.substring(0, fixedName.length - valStr.length).trim();
        }
        final nameForCanon = fixedName;

        final value  = double.tryParse(valStr);
        final refMin = double.tryParse(loStr);
        final refMax = double.tryParse(hiStr);
        if (value == null) continue;

        // حارس رينج: تجاهل سنوات/سالب
        double? rMin = refMin;
        double? rMax = refMax;
        bool isYear(num x) => x >= 1900 && x <= 2100;
        if (rMin != null && rMax != null) {
          if (rMin < 0 || isYear(rMin) || isYear(rMax)) {
            rMin = double.nan;
            rMax = double.nan;
          }
        }

        // القاموس
        final canonical = await TermDictionary.canonicalize(nameForCanon);

        if (canonical == null) {
          tests.add(LabTest(
            code: nameForCanon,
            name: nameForCanon,
            value: value,
            refMin: rMin ?? double.nan,
            refMax: rMax ?? double.nan,
          ));
          continue;
        }

        final info = await TermDictionary.info(canonical);
        final double lo = (rMin ?? info?.refMin) ?? double.nan;
        final double hi = (rMax ?? info?.refMax) ?? double.nan;

        tests.add(LabTest(
          code: canonical,
          name: canonical,
          value: value,
          refMin: lo,
          refMax: hi,
        ));
      }
    }

    doc.dispose();
    return tests;
  }
}
