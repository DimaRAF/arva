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

  // 1) أنماط وحدات شائعة
  const unitPattern =
      r'(?:10\^\d+\/[A-Za-z]+|g\/dL|mg\/dL|mmol\/L|µ?mol\/L|ng\/mL|IU\/L|U\/L|fL|pg|%|10\^9\/L|10\^3\/µL|cells\/µL|K\/µL|x10\^\d+\/u?l)';

  // 2) سطر التحليل (مجموعات مرقّمة):
  // (1)=name  (2)=unit?  (3)=value  (4)=refmin  (5)=refmax
  final rowRe = RegExp(
    r'([A-Za-z][A-Za-z0-9 /()\-\+:%\.]*?)\s*' // 1 name
    r'(' + unitPattern + r')?\s*'             // 2 unit (optional)
    r'(-?\d+(?:\.\d+)?)'                      // 3 value
    r'(?:[^\d\-]{0,40})?'                     // noise between value & range
    r'(-?\d+(?:\.\d+)?)\s*[-–]\s*'            // 4 ref min
    r'(-?\d+(?:\.\d+)?)',                     // 5 ref max
    caseSensitive: false,
    dotAll: true,
  );

  final tests = <LabTest>[];

  for (int i = 0; i < doc.pages.count; i++) {
    var text = ext.extractText(startPageIndex: i, endPageIndex: i);
    debugPrint('[PDF] page $i chars=${text.length}');

    // --- Normalize ---
    text = text
        .replaceAll('\r', ' ')
        .replaceAll('\t', ' ')
        .replaceAll('\u200f', ' ')
        .replaceAll('\u200e', ' ')
        .replaceAll('–', '-');

    // شيل تواريخ/أوقات (AM/PM) عشان ما تلوّث المطابقة
    final dateTimeRe = RegExp(
      r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b(?:\s+\d{1,2}:\d{2}\s?(?:AM|PM))?',
      caseSensitive: false,
    );
    text = text.replaceAll(dateTimeRe, ' ');

    // فاصلة بين الوحدة والقيمة لو ملزوقين: mg/dL3.3 -> mg/dL 3.3
    text = text.replaceAllMapped(
      RegExp('($unitPattern)(?=\\d)', caseSensitive: false),
      (m) => '${m[0]} ',
    );

    // فكّ التصاق القيمة بالرينج: 318180 - 1100 -> 318 180 - 1100
    text = text.replaceAllMapped(
      RegExp(r'(\d{2,})(?=\d{2,}\s*-\s*\d)'),
      (m) => '${m[1]} ',
    );

    // مسافات إضافية
    text = text.replaceAllMapped(RegExp(r'[ ]{2,}'), (m) => ' ');

    // --- Match rows ---
    final matches = rowRe.allMatches(text).toList();
    debugPrint('[PDF] page $i found rows=${matches.length}');

    for (final m in matches) {
      // 1=name, 3=value, 4=min, 5=max
      final rawName = (m.group(1) ?? '').trim();
      final valStr  = (m.group(3) ?? '').trim();
      final loStr   = (m.group(4) ?? '').trim();
      final hiStr   = (m.group(5) ?? '').trim();

      // استبعاد أسطر ليست تحاليل (أضفت Patient ID)
      final badName = RegExp(
        r'^(?:Patient\s*Name|Patient\s*ID|Gender|Age|Visit\s*Number|Result|Reference\s*Range|Refrence\s*Range|Unit|Registered|Authenticated|Printed|\(AM\)|\(PM\)|AM|PM|Branch\s*Name)$',
        caseSensitive: false,
      );
      if (badName.hasMatch(rawName)) continue;

      // لو الاسم ملتصق بالقيمة: "Red cell count4.72"
      var fixedName = rawName;
      if (valStr.isNotEmpty &&
          fixedName.toLowerCase().endsWith(valStr.toLowerCase())) {
        fixedName = fixedName.substring(0, fixedName.length - valStr.length).trim();
      }
      final nameForCanon = fixedName;

      final value  = double.tryParse(valStr);
      final refMin = double.tryParse(loStr);
      final refMax = double.tryParse(hiStr);
      if (value == null) continue;

      // حارس للرينج: تجاهل سنين/قيم سالبة واضحة
      double? rMin = refMin;
      double? rMax = refMax;
      bool isYear(num x) => x >= 1900 && x <= 2100;
      if (rMin != null && rMax != null) {
        if (rMin < 0 || isYear(rMin) || isYear(rMax)) {
          rMin = double.nan;
          rMax = double.nan;
        }
      }

      // قاموس المصطلحات
      final canonical = await TermDictionary.canonicalize(nameForCanon);

      if (canonical == null) {
        // اسم جديد → خليه يمرّ وسنقرر لاحقًا
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

    // مثال خاص: AST/ALT Ratio بصيغة "< 2"
    final ratioRe = RegExp(
      r'([A-Za-z/ ]+Ratio)\s*(-?\d+(?:\.\d+)?)\D+<\s*(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
      dotAll: true,
    );
    for (final m in ratioRe.allMatches(text)) {
      final n  = (m.group(1) ?? '').trim();
      final v  = double.tryParse((m.group(2) ?? '').trim());
      final mx = double.tryParse((m.group(3) ?? '').trim());
      if (v == null) continue;
      final canonical = await TermDictionary.canonicalize(n) ?? n;
      tests.add(LabTest(
        code: canonical,
        name: canonical,
        value: v,
        refMin: double.nan,
        refMax: mx ?? double.nan,
      ));
    }
  }

  doc.dispose();
  return tests;
}


}
