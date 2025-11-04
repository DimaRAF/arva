// services/pdf_extractor.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';
import '../models/lab_test.dart';
import 'term_dictionary.dart';

class PdfExtractor {
  /// قراءة من مسار ملف محلي
  static Future<List<LabTest>> parse(String pdfPath) async {
    final bytes = await File(pdfPath).readAsBytes();
    return _parseBytes(Uint8List.fromList(bytes));
  }

  /// قراءة من أصول (assets)
  static Future<List<LabTest>> parseAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return _parseBytes(data.buffer.asUint8List());
  }

  /// ✅ واجهة عامة لتمرير بايتات الملف مباشرة (مثالية لملف مختار من الجوال)
  static Future<List<LabTest>> parseBytes(Uint8List bytes) async {
    return _parseBytes(bytes);
  }

  /// المنفِّذ الفعلي لتحليل البايتات
  static Future<List<LabTest>> _parseBytes(Uint8List bytes) async {
    final doc = PdfDocument(inputBytes: bytes);
    final ext = PdfTextExtractor(doc);

    // جميع صيغ الوحدات الشائعة
    const unitPattern =
        r'(?:'
        r'10\^\d+\/[A-Za-z]+'
        r'|g\/dL|mg\/dL|µg\/mL|ug\/mL|ng\/mL|pg\/mL'
        r'|mmol\/L|µ?mol\/L'
        r'|IU\/L|U\/L|mIU\/L|µIU\/L|uIU\/L|uIU\/mL|µIU\/mL|mIU\/mL'
        r'|fL|pL|nL|pg|ng|%'
        r'|10\^9\/L|10\^6\/µL|10\^3\/µL'
        r'|cells\/µL|K\/µL|x10\^\d+\/u?l'
        r')';

    // صف: name  value  [unit]  ...  a-b
    final rowRe = RegExp(
      r'([A-Za-z][A-Za-z0-9 /()\-\+:%\.]*?)\s+'      // (1) الاسم
      r'(-?\d+(?:\.\d+)?)\s*'                        // (2) القيمة
      r'(?:' + unitPattern + r')?\s*'                //     وحدة (اختياري)
      r'(?:[^\n]{0,80}?)'                            //     ضجيج
      r'(-?\d+(?:\.\d+)?)\s*[-–]\s*(-?\d+(?:\.\d+)?)', // (3)(4) الرينج
      caseSensitive: false,
      dotAll: true,
    );

    // سطور/عناوين ليست تحاليل
    final badName = RegExp(
      r'^(?:Patient\s*Name|Gender|Age|Visit\s*Number|Patient\s*ID|File\s*No|Lab\s*No|Result|Reference\s*Range|Refrence\s*Range|Unit|Registered|Authenticated|Printed|\(AM\)|\(PM\)|AM|PM|Branch\s*Name|Less\s*than|ul|Collection Date and Time:|DOB)$',
      caseSensitive: false,
    );

    // جُمل تفسيرية
    final commentLine = RegExp(
      r'\b(less\s*than|greater\s*than|means\s+you|ideal|good|bad|deficient|insufficient|sufficient|normal\s*range|comment|interpretation|gfr\s+of|under\s+\d)\b',
      caseSensitive: false,
    );

    // رموز مفردة أو وحدة فقط
    final tokenOnly = RegExp(r'^\(?[LH]\)?$', caseSensitive: false);
    final unitOnly = RegExp('^(?:' + unitPattern + r')$', caseSensitive: false);

    // نسب من نوع: AST/ALT Ratio 1.1 … < 2
    final ratioRe = RegExp(
      r'([A-Za-z/ ]+Ratio)\s*(-?\d+(?:\.\d+)?)\D*<\s*(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
      dotAll: true,
    );

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

      // احذف تواريخ/أوقات (AM/PM)
      final dateTimeRe = RegExp(
        r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b(?:\s+\d{1,2}:\d{2}\s?(?:AM|PM))?',
        caseSensitive: false,
      );
      text = text.replaceAll(dateTimeRe, ' ');

      // أضف مسافة بعد الوحدة إن تبعها رقم: mg/dL3.33 → mg/dL 3.33
      text = text.replaceAllMapped(
        RegExp('(' + unitPattern + r')(?=\d)', caseSensitive: false),
        (m) => '${m[1]} ',
      );

      // مسافة بين حرف/قوس ورقم مباشر: count4.72 → count 4.72
      text = text.replaceAllMapped(
        RegExp(r'([A-Za-z\)])(?=\d)'),
        (m) => '${m[1]} ',
      );

      // فك التصاق أرقام كبيرة قبل الرينج: 318180 - 1100 → 318 180 - 1100
      text = text.replaceAllMapped(
        RegExp(r'(\d{2,})(?=\d{2,}\s*-\s*\d)'),
        (m) => '${m[1]} ',
      );

      // طي المسافات
      text = text.replaceAll(RegExp(r'[ ]{2,}'), ' ');

      // مطابقة صفوف التحاليل
      final matches = rowRe.allMatches(text);
      debugPrint('[PDF] page $i found rows=${matches.length}');

      for (final m in matches) {
        final rawName = (m.group(1) ?? '').trim();
        if (badName.hasMatch(rawName)) continue;

        final valStr = (m.group(2) ?? '').trim();
        final loStr = (m.group(3) ?? '').trim();
        final hiStr = (m.group(4) ?? '').trim();

        // اسم مُنقّى
        var fixedName = rawName;

        // لو القيمة ملتصقة بنهاية الاسم
        if (valStr.isNotEmpty &&
            fixedName.toLowerCase().endsWith(valStr.toLowerCase())) {
          fixedName =
              fixedName.substring(0, fixedName.length - valStr.length).trim();
        }

        // احذف الوحدة فقط إذا كانت في "ذيل" الاسم (اختياري بين أقواس)
        final unitTail = RegExp(
          r'\s*\(?(?:' + unitPattern + r')\)?\s*$',
          caseSensitive: false,
        );
        fixedName = fixedName.replaceAll(unitTail, '').trim();

        // إن أصبح الاسم وحدة فقط → تجاهل
        final onlyUnitName = RegExp(
          r'^\(?\s*(?:' + unitPattern + r')\s*\)?$',
          caseSensitive: false,
        );
        if (fixedName.isEmpty || onlyUnitName.hasMatch(fixedName)) continue;

        // تنظيف إضافي: أقواس فارغة + مسافات
        fixedName = fixedName
            .replaceAll(RegExp(r'\(\s*\)'), '')
            .replaceAll(RegExp(r'\s{2,}'), ' ')
            .trim();

        // فلترة جُمل تفسيرية/رموز
        if (fixedName.length < 2 ||
            tokenOnly.hasMatch(fixedName) ||
            unitOnly.hasMatch(fixedName) ||
            commentLine.hasMatch(fixedName)) {
          continue;
        }

        final value = double.tryParse(valStr);
        final refMin = double.tryParse(loStr);
        final refMax = double.tryParse(hiStr);
        if (value == null) continue;

        // حارس للرينج: تجاهل سنوات/قيم سالبة غير منطقية
        double? rMin = refMin;
        double? rMax = refMax;
        bool isYear(num x) => x >= 1900 && x <= 2100;
        if (rMin != null && rMax != null) {
          if (rMin < 0 || isYear(rMin) || isYear(rMax)) {
            rMin = double.nan;
            rMax = double.nan;
          }
        }

        // ربط بالقاموس
        final canonical = await TermDictionary.canonicalize(fixedName);
        if (canonical == null) {
          tests.add(LabTest(
            code: fixedName,
            name: fixedName,
            value: value,
            refMin: rMin ?? double.nan,
            refMax: rMax ?? double.nan,
          ));
          continue;
        }

        // عند التطابق مع القاموس: خذ الرينج من القاموس فقط
        final info = await TermDictionary.info(canonical);
        final double lo = info?.refMin ?? double.nan;
        final double hi = info?.refMax ?? double.nan;

        tests.add(LabTest(
          code: canonical,
          name: canonical,
          value: value,
          refMin: lo,
          refMax: hi,
        ));
      }

      // مطابقة صيغ Ratio: "... Ratio 1.1 ... < 2"
      for (final m in ratioRe.allMatches(text)) {
        var n = (m.group(1) ?? '').trim();
        if (badName.hasMatch(n) || commentLine.hasMatch(n)) continue;

        // نظّف ذيل الاسم من الوحدة إن وُجدت
        final unitTail = RegExp(
          r'\s*\(?(?:' + unitPattern + r')\)?\s*$',
          caseSensitive: false,
        );
        n = n.replaceAll(unitTail, '').trim();

        final vStr = (m.group(2) ?? '').trim();
        final mxStr = (m.group(3) ?? '').trim();
        final value = double.tryParse(vStr);
        final max = double.tryParse(mxStr);
        if (value == null) continue;

        final canonical = await TermDictionary.canonicalize(n) ?? n;
        tests.add(LabTest(
          code: canonical,
          name: canonical,
          value: value,
          refMin: double.nan,          // حد أدنى غير معروف
          refMax: max ?? double.nan,   // حد أعلى فقط
        ));
      }
    }

    doc.dispose();
    return tests;
  }
}
