import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';
import '../models/lab_test.dart';
import 'term_dictionary.dart';

class PdfExtractor {
 
  static Future<List<LabTest>> parse(String pdfPath) async {
    // Await an asynchronous operation.
    final bytes = await File(pdfPath).readAsBytes();
    return _parseBytes(Uint8List.fromList(bytes));
  }


  static Future<List<LabTest>> parseAsset(String assetPath) async {
    // Await an asynchronous operation.
    final data = await rootBundle.load(assetPath);
    return _parseBytes(data.buffer.asUint8List());
  }

  
  static Future<List<LabTest>> parseBytes(Uint8List bytes) async {
    return _parseBytes(bytes);
  }

  
  static Future<List<LabTest>> _parseBytes(Uint8List bytes) async {
    final doc = PdfDocument(inputBytes: bytes);
    final ext = PdfTextExtractor(doc);

   
    const unitPattern =
    r'(?:'
    r'10\^\d+\/[A-Za-z]+'
    r'|g\/dL|mg\/dL|µg\/mL|ug\/mL|ng\/mL|pg\/mL|ug\/dL'
    r'|mmol\/L|µ?mol\/L'
    r'|IU\/L|U\/L|mIU\/L|µIU\/L|uIU\/L|uIU\/mL|µIU\/mL|mIU\/mL'
    r'|fL|pL|nL|pg|ng|%'
    r'|10\^9\/L|10\^6\/µL|10\^3\/µL'
    r'|cells\/µL|K\/µL|x10\^\d+\/u?l'
    r')';

   
    final rowRe = RegExp(
      r'([A-Za-z][A-Za-z0-9 /()\-\+:%\.]*?)\s+'     
      r'(-?\d+(?:\.\d+)?)\s*'                       
      r'(?:' + unitPattern + r')?\s*'               
      r'(?:[^\n]{0,80}?)'                           
      r'(-?\d+(?:\.\d+)?)\s*[-–]\s*(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
      dotAll: true,
    );


    final badName = RegExp(
      r'^(?:Patient\s*Name|Gender|Age|Visit\s*Number|Patient\s*ID|File\s*No|Lab\s*No|Result|Reference\s*Range|Refrence\s*Range|Unit|Registered|Authenticated|Printed|\(AM\)|\(PM\)|AM|PM|Branch\s*Name|Less\s*than|ul|(Fe)u|Collection Date and Time:|DOB)$',
      caseSensitive: false,
    );


    final commentLine = RegExp(
      r'\b(less\s*than|greater\s*than|means\s+you|ideal|good|bad|deficient|insufficient|sufficient|normal\s*range|comment|interpretation|gfr\s+of|under\s+\d)\b',
      caseSensitive: false,
    );

    final tokenOnly = RegExp(r'^\(?[LH]\)?$', caseSensitive: false);
    final unitOnly = RegExp('^(?:' + unitPattern + r')$', caseSensitive: false);


    final ratioRe = RegExp(
      r'([A-Za-z/ ]+Ratio)\s*(-?\d+(?:\.\d+)?)\D*<\s*(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
      dotAll: true,
    );

    final tests = <LabTest>[];

    // Loop over a collection to apply logic.
    for (int i = 0; i < doc.pages.count; i++) {
      var text = ext.extractText(startPageIndex: i, endPageIndex: i);
      debugPrint('[PDF] page $i chars=${text.length}');

      text = text
          .replaceAll('\r', ' ')
          .replaceAll('\t', ' ')
          .replaceAll('\u200f', ' ')
          .replaceAll('\u200e', ' ')
          .replaceAll('–', '-');

  
      final dateTimeRe = RegExp(
        r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b(?:\s+\d{1,2}:\d{2}\s?(?:AM|PM))?',
        caseSensitive: false,
      );
      text = text.replaceAll(dateTimeRe, ' ');

     
      text = text.replaceAllMapped(
        RegExp('(' + unitPattern + r')(?=\d)', caseSensitive: false),
        (m) => '${m[1]} ',
      );


      text = text.replaceAllMapped(
        RegExp(r'([A-Za-z\)])(?=\d)'),
        (m) => '${m[1]} ',
      );

      text = text.replaceAllMapped(
        RegExp(r'(\d{2,})(?=\d{2,}\s*-\s*\d)'),
        (m) => '${m[1]} ',
      );

      text = text.replaceAll(RegExp(r'[ ]{2,}'), ' ');


      final matches = rowRe.allMatches(text);
      debugPrint('[PDF] page $i found rows=${matches.length}');

      // Loop over a collection to apply logic.
      for (final m in matches) {
        final rawName = (m.group(1) ?? '').trim();
        // Branch on a condition that affects logic flow.
        if (badName.hasMatch(rawName)) continue;

        final valStr = (m.group(2) ?? '').trim();
        final loStr = (m.group(3) ?? '').trim();
        final hiStr = (m.group(4) ?? '').trim();

       
        var fixedName = rawName;

       
        // Branch on a condition that affects logic flow.
        if (valStr.isNotEmpty &&
            fixedName.toLowerCase().endsWith(valStr.toLowerCase())) {
          fixedName =
              fixedName.substring(0, fixedName.length - valStr.length).trim();
        }

       
        final unitTail = RegExp(
          r'\s*\(?(?:' + unitPattern + r')\)?\s*$',
          caseSensitive: false,
        );
        fixedName = fixedName.replaceAll(unitTail, '').trim();

       
        final onlyUnitName = RegExp(
          r'^\(?\s*(?:' + unitPattern + r')\s*\)?$',
          caseSensitive: false,
        );
        // Branch on a condition that affects logic flow.
        if (fixedName.isEmpty || onlyUnitName.hasMatch(fixedName)) continue;

       
        fixedName = fixedName
            .replaceAll(RegExp(r'\(\s*\)'), '')
            .replaceAll(RegExp(r'\s{2,}'), ' ')
            .trim();

   
        // Branch on a condition that affects logic flow.
        if (fixedName.length < 2 ||
            tokenOnly.hasMatch(fixedName) ||
            unitOnly.hasMatch(fixedName) ||
            commentLine.hasMatch(fixedName)) {
          continue;
        }

        final value = double.tryParse(valStr);
        final refMin = double.tryParse(loStr);
        final refMax = double.tryParse(hiStr);
        // Branch on a condition that affects logic flow.
        if (value == null) continue;

       
        double? rMin = refMin;
        double? rMax = refMax;
        bool isYear(num x) => x >= 1900 && x <= 2100;
        // Branch on a condition that affects logic flow.
        if (rMin != null && rMax != null) {
          // Branch on a condition that affects logic flow.
          if (rMin < 0 || isYear(rMin) || isYear(rMax)) {
            rMin = double.nan;
            rMax = double.nan;
          }
        }

      
        // Await an asynchronous operation.
        final canonical = await TermDictionary.canonicalize(fixedName);
        // Branch on a condition that affects logic flow.
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

       
        // Await an asynchronous operation.
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

      // Loop over a collection to apply logic.
      for (final m in ratioRe.allMatches(text)) {
        var n = (m.group(1) ?? '').trim();
        // Branch on a condition that affects logic flow.
        if (badName.hasMatch(n) || commentLine.hasMatch(n)) continue;

    
        final unitTail = RegExp(
          r'\s*\(?(?:' + unitPattern + r')\)?\s*$',
          caseSensitive: false,
        );
        n = n.replaceAll(unitTail, '').trim();

        final vStr = (m.group(2) ?? '').trim();
        final mxStr = (m.group(3) ?? '').trim();
        final value = double.tryParse(vStr);
        final max = double.tryParse(mxStr);
        // Branch on a condition that affects logic flow.
        if (value == null) continue;

        // Await an asynchronous operation.
        final canonical = await TermDictionary.canonicalize(n) ?? n;
        tests.add(LabTest(
          code: canonical,
          name: canonical,
          value: value,
          refMin: double.nan,         
          refMax: max ?? double.nan,   // حد أعلى فقط
        ));
      }
    }

    doc.dispose();
    return tests;
  }
}
