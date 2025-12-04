import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;

class TermInfo {
  final String canonical;        //  original_medical term
  final double? refMin;          // Lowest_Normal
  final double? refMax;          // Highest_Normal
  final String unit;             // Unit
  const TermInfo({
    required this.canonical,
    this.refMin,
    this.refMax,
    required this.unit,
  });
}

class TermDictionary {
  static bool _loaded = false;

  /// "Iron"  -> info )
  static final Map<String, TermInfo> _byCanonical = {};

  /// "IRON (FE)" / "SERUM IRON" / "Fe" -> "Iron"
  static final Map<String, String> _aliasToCanonical = {};

 
  static Future<void> ensureLoaded() async {
    if (_loaded) return;

    final bytes = await rootBundle.load('assets/ALL_medical term.xlsx');
    final excel = Excel.decodeBytes(bytes.buffer.asUint8List());
    final sheet = excel.tables[excel.tables.keys.first]!;

   
    final headers = sheet.rows.first
        .map((c) => (c?.value?.toString().trim() ?? '').toLowerCase())
        .toList();

    // original_medical term + medical term1..4
    final int idxOriginal = headers.indexOf('original_medical term');
    final int idxMT1      = headers.indexOf('medical term1');
    final int idxMT2      = headers.indexOf('medical term2');
    final int idxMT3      = headers.indexOf('medical term3');
    final int idxMT4      = headers.indexOf('medical term4');

   
    final int idxCanonicalCol =
        (idxOriginal >= 0) ? idxOriginal : headers.indexOf('medical term');

    if (idxCanonicalCol < 0) {
      throw Exception(
          '❌ Neither "original_medical term" nor "medical term" column found in Excel');
    }

    final int idxLo   = headers.indexOf('lowest_normal');
    final int idxHi   = headers.indexOf('highest_normal');
    final int idxUnit = headers.indexOf('unit');

    for (int r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];


      final String canonicalName = _s(row, idxCanonicalCol);
      if (canonicalName.isEmpty) continue;

      final double? lo  = _d(row, idxLo);
      final double? hi  = _d(row, idxHi);
      final String unit = _s(row, idxUnit);

      final String canon = _canon(canonicalName);


      final info = TermInfo(
        canonical: canon,
        refMin: lo,
        refMax: hi,
        unit: unit,
      );
      _byCanonical[canon] = info;

    
      final Set<String> rawNames = {canonicalName};

      if (idxMT1 >= 0) {
        final s = _s(row, idxMT1);
        if (s.isNotEmpty) rawNames.add(s);
      }
      if (idxMT2 >= 0) {
        final s = _s(row, idxMT2);
        if (s.isNotEmpty) rawNames.add(s);
      }
      if (idxMT3 >= 0) {
        final s = _s(row, idxMT3);
        if (s.isNotEmpty) rawNames.add(s);
      }
      if (idxMT4 >= 0) {
        final s = _s(row, idxMT4);
        if (s.isNotEmpty) rawNames.add(s);
      }

  
      for (final raw in rawNames) {
        for (final alias in _generateAliases(raw)) {
          _aliasToCanonical[alias] = canon;
        }

       
        final short = _extractShort(raw);
        if (short != null) {
          _aliasToCanonical[_norm(short)] = canon;
        }
      }
    }

    _loaded = true;
  }

 

  static String _s(List<Data?> row, int idx) {
    if (idx < 0) return '';
    final v = row[idx]?.value;
    return (v == null) ? '' : v.toString().trim();
  }

  static double? _d(List<Data?> row, int idx) {
    if (idx < 0) return null;
    final v = row[idx]?.value;
    if (v == null) return null;
    final s = v.toString().replaceAll(',', '.').trim();
    return double.tryParse(s);
  }

 
  static String _canon(String s) => s.trim();


  static String _norm(String s) => s
      .toUpperCase()
      .replaceAll(RegExp(r'[\t\r\n]'), ' ')
      .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Iterable<String> _generateAliases(String name) {
    final aliases = <String>{};
    aliases.add(_norm(name));
  
    aliases.add(_norm(name.replaceAll(RegExp(r'\(.*?\)'), '')));
    return aliases.where((e) => e.isNotEmpty);
  }

  static String? _extractShort(String name) {
    final m = RegExp(r'\(([A-Za-z0-9+\- ]{2,15})\)').firstMatch(name);
    if (m == null) return null;
    final s = m.group(1)!.trim();
    if (s.length < 2) return null;
    return s;
  }

  /// يحوّل اسم من الـPDF (أو من التقرير) إلى الاسم القياسي من عمود original_medical term
  /// مثلاً: "Iron (Fe)" أو "SERUM IRON" → "Iron"
  static Future<String?> canonicalize(String pdfName) async {
    await ensureLoaded();
    return _aliasToCanonical[_norm(pdfName)];
  }

  /// يرجّع معلومات التحليل حسب الاسم القياسي (نفس عمود original_medical term)
  static Future<TermInfo?> info(String canonical) async {
    await ensureLoaded();
    return _byCanonical[canonical];
  }
}
