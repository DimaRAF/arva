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

   const unitPattern =
  r'(?:'
  r'10\^\d+\/[A-Za-z]+'                          // x10^n/...
  r'|g\/dL|mg\/dL|µg\/mL|ug\/mL|ng\/mL|pg\/mL'   // تركيز شائع
  r'|mmol\/L|µ?mol\/L'                           // مولارية
  r'|IU\/L|U\/L|mIU\/L|µIU\/L|uIU\/L'            // IU لكل لتر
  r'|uIU\/mL|µIU\/mL|mIU\/mL'                    // IU لكل مل
  r'|fL|pL|nL|pg|ng|%'                           // وحدات مفردة
  r'|10\^9\/L|10\^6\/µL|10\^3\/µL'               // صور CBC
  r'|cells\/µL|K\/µL|x10\^\d+\/u?l'              // صيغ بديلة
  r')';


    // صف: name value [unit] refmin - refmax
    // (1)=name, (2)=value, (3)=refmin, (4)=refmax
    final rowRe = RegExp(
      r'([A-Za-z][A-Za-z0-9 /()\-\+:%\.]*?)\s+'         // name
      r'(-?\d+(?:\.\d+)?)\s*'                           // value
      r'(?:' + unitPattern + r')?\s*'                   // optional unit
      r'(?:[^\n]{0,80}?)'                               // noise
      r'(-?\d+(?:\.\d+)?)\s*[-–]\s*(-?\d+(?:\.\d+)?)',  // range
      caseSensitive: false,
      dotAll: true,
    );

    // جُمل/عناوين نرفضها كأسماء تحاليل
    final badName = RegExp(
      r'^(?:Patient\s*Name|Gender|Age|Visit\s*Number|Patient\s*ID|File\s*No|Lab\s*No|Result|Reference\s*Range|Refrence\s*Range|Unit|Registered|Authenticated|Printed|\(AM\)|\(PM\)|AM|PM|Branch\s*Name|Less\s*than)$',
      caseSensitive: false,
    );

    // جُمل تفسيرية (مثل: less than / ideal / good / bad / deficient …)
    final commentLine = RegExp(
      r'\b(less\s*than|greater\s*than|means\s+you|ideal|good|bad|deficient|insufficient|sufficient|normal\s*range|comment|interpretation|gfr\s+of|under\s+\d)\b',
      caseSensitive: false,
    );

    // رموز مفردة L/H أو وحدة لوحدها
    final tokenOnly = RegExp(r'^\(?[LH]\)?$', caseSensitive: false);
    final unitOnly  = RegExp('^$unitPattern\$', caseSensitive: false);

    // نمط لنِسَب من نوع: AST/ALT Ratio 1.1 … < 2
    // (1)=name, (2)=value, (3)=max
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

      // افصل الوحدة عن القيمة: mg/dL3.33 → mg/dL 3.33
      text = text.replaceAllMapped(
        RegExp('($unitPattern)(?=\\d)', caseSensitive: false),
        (m) => '${m[0]} ',
      );

      // افصل حرف/قوس قبل رقم: count4.72 → count 4.72
      text = text.replaceAllMapped(
        RegExp(r'([A-Za-z\)])(?=\d)'),
        (m) => '${m[1]} ',
      );

      // فك التصاق أرقام كبيرة قبل الرينج: 318180 - 1100 → 318 180 - 1100
      text = text.replaceAllMapped(
        RegExp(r'(\d{2,})(?=\d{2,}\s*-\s*\d)'),
        (m) => '${m[1]} ',
      );

      // مسافات مكررة
      text = text.replaceAllMapped(RegExp(r'[ ]{2,}'), (m) => ' ');

      // صفوف "name value … a-b"
      for (final m in rowRe.allMatches(text)) {
        final rawName = (m.group(1) ?? '').trim();
        final valStr  = (m.group(2) ?? '').trim();
        final loStr   = (m.group(3) ?? '').trim();
        final hiStr   = (m.group(4) ?? '').trim();

        if (badName.hasMatch(rawName)) continue;

// تنظيف الاسم من الوحدات أينما ظهرت + الأقواس الفارغة + المسافات
var fixedName = rawName
    .replaceAll(RegExp('(?:$unitPattern)\$', caseSensitive: false), '')
    .replaceAll(RegExp(unitPattern, caseSensitive: false), '')
    .replaceAll(RegExp(r'\(\s*\)', caseSensitive: false), '')
    .replaceAll(RegExp(r'\s{2,}'), ' ')
    .trim();

// أحياناً القيمة تكون لازقة بآخر الاسم: "count4.72" → "count 4.72"
if (valStr.isNotEmpty &&
    fixedName.toLowerCase().endsWith(valStr.toLowerCase())) {
  fixedName = fixedName.substring(0, fixedName.length - valStr.length).trim();
}

// إن أصبح الاسم وحدة فقط (مثل "uL" أو "(uL)") → تجاهل السطر
final onlyUnit = RegExp(r'^\(?\s*(?:uL|µL|mL)\s*\)?$', caseSensitive: false);
if (fixedName.isEmpty || onlyUnit.hasMatch(fixedName)) {
  continue; // لا نضيف هذا كتحليل
}

final nameForCanon = fixedName;


// أحيانًا القيمة تلزق بآخر الاسم: "count4.72" → افصلها
if (valStr.isNotEmpty &&
    fixedName.toLowerCase().endsWith(valStr.toLowerCase())) {
  fixedName = fixedName.substring(0, fixedName.length - valStr.length).trim();
}



// 2) شيل أي وحدة ظهرت جوّا الاسم (مثلاً "Insulin Level uIU/mL")
fixedName = fixedName.replaceAll(
  RegExp(unitPattern, caseSensitive: false),
  '',
).trim();

// 3) شيل الأقواس الفارغة الناتجة عن إزالة الوحدة
fixedName = fixedName.replaceAll(RegExp(r'\(\s*\)'), '').trim();

// 4) وحّد المسافات
fixedName = fixedName.replaceAll(RegExp(r'\s{2,}'), ' ').trim();


        // لو القيمة ملتصقة بنهاية الاسم
        if (valStr.isNotEmpty &&
            fixedName.toLowerCase().endsWith(valStr.toLowerCase())) {
          fixedName =
              fixedName.substring(0, fixedName.length - valStr.length).trim();
        }

        // فلتر جُمل تفسيرية / رموز / وحدة فقط
        if (fixedName.length < 2 ||
            tokenOnly.hasMatch(fixedName) ||
            unitOnly.hasMatch(fixedName) ||
            commentLine.hasMatch(fixedName)) {
          continue;
        }

        final value  = double.tryParse(valStr);
        final refMin = double.tryParse(loStr);
        final refMax = double.tryParse(hiStr);
        if (value == null) continue;

        // حارس للرّينج: تجاهل سنوات/سالب
        double? rMin = refMin;
        double? rMax = refMax;
        bool isYear(num x) => x >= 1900 && x <= 2100;
        if (rMin != null && rMax != null) {
          if (rMin < 0 || isYear(rMin) || isYear(rMax)) {
            rMin = double.nan;
            rMax = double.nan;
          }
        }

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

        final info = await TermDictionary.info(canonical);
        final double lo = (rMin ?? info?.refMin) ?? double.nan;
        final double hi = (rMax ?? info?.refMax) ?? double.nan;

        tests.add(LabTest(
          code: canonical.toUpperCase(),
          name: canonical,
          value: value,
          refMin: lo,
          refMax: hi,
        ));
      }

      // صفوف نسب: "… Ratio 1.1 … < 2"
      for (final m in ratioRe.allMatches(text)) {
        var n = (m.group(1) ?? '').trim();
        if (badName.hasMatch(n) || commentLine.hasMatch(n)) continue;

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
          refMin: double.nan,
          refMax: max ?? double.nan,
        ));
      }
    }

    doc.dispose();
    return tests;
  }
}
