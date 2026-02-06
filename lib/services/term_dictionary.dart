import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;

class TermInfo {
  final String canonical;        
  final double? refMin;          
  final double? refMax;          
  final String unit;             
  const TermInfo({
    required this.canonical,
    this.refMin,
    this.refMax,
    required this.unit,
  });
}

class TermDictionary {
  static bool _loaded = false;

  
  static final Map<String, TermInfo> _byCanonical = {};

  
  static final Map<String, String> _aliasToCanonical = {};

 
  static Future<void> ensureLoaded() async {
    // Branch on a condition that affects logic flow.
    if (_loaded) return;

    // Await an asynchronous operation.
    final bytes = await rootBundle.load('assets/ALL_medical term.xlsx');
    final excel = Excel.decodeBytes(bytes.buffer.asUint8List());
    final sheet = excel.tables[excel.tables.keys.first]!;

   
    final headers = sheet.rows.first
        .map((c) => (c?.value?.toString().trim() ?? '').toLowerCase())
        .toList();

    final int idxOriginal = headers.indexOf('original_medical term');
    final int idxMT1      = headers.indexOf('medical term1');
    final int idxMT2      = headers.indexOf('medical term2');
    final int idxMT3      = headers.indexOf('medical term3');
    final int idxMT4      = headers.indexOf('medical term4');

   
    final int idxCanonicalCol =
        (idxOriginal >= 0) ? idxOriginal : headers.indexOf('medical term');

    // Branch on a condition that affects logic flow.
    if (idxCanonicalCol < 0) {
      throw Exception(
          '❌ Neither "original_medical term" nor "medical term" column found in Excel');
    }

    final int idxLo   = headers.indexOf('lowest_normal');
    final int idxHi   = headers.indexOf('highest_normal');
    final int idxUnit = headers.indexOf('unit');

    // Loop over a collection to apply logic.
    for (int r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];


      final String canonicalName = _s(row, idxCanonicalCol);
      // Branch on a condition that affects logic flow.
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

      // Branch on a condition that affects logic flow.
      if (idxMT1 >= 0) {
        final s = _s(row, idxMT1);
        // Branch on a condition that affects logic flow.
        if (s.isNotEmpty) rawNames.add(s);
      }
      // Branch on a condition that affects logic flow.
      if (idxMT2 >= 0) {
        final s = _s(row, idxMT2);
        // Branch on a condition that affects logic flow.
        if (s.isNotEmpty) rawNames.add(s);
      }
      // Branch on a condition that affects logic flow.
      if (idxMT3 >= 0) {
        final s = _s(row, idxMT3);
        // Branch on a condition that affects logic flow.
        if (s.isNotEmpty) rawNames.add(s);
      }
      // Branch on a condition that affects logic flow.
      if (idxMT4 >= 0) {
        final s = _s(row, idxMT4);
        // Branch on a condition that affects logic flow.
        if (s.isNotEmpty) rawNames.add(s);
      }

  
      // Loop over a collection to apply logic.
      for (final raw in rawNames) {
        // Loop over a collection to apply logic.
        for (final alias in _generateAliases(raw)) {
          _aliasToCanonical[alias] = canon;
        }

       
        final short = _extractShort(raw);
        // Branch on a condition that affects logic flow.
        if (short != null) {
          _aliasToCanonical[_norm(short)] = canon;
        }
      }
    }

    _loaded = true;
  }

 

  static String _s(List<Data?> row, int idx) {
    // Branch on a condition that affects logic flow.
    if (idx < 0) return '';
    final v = row[idx]?.value;
    return (v == null) ? '' : v.toString().trim();
  }

  static double? _d(List<Data?> row, int idx) {
    // Branch on a condition that affects logic flow.
    if (idx < 0) return null;
    final v = row[idx]?.value;
    // Branch on a condition that affects logic flow.
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
    // Branch on a condition that affects logic flow.
    if (m == null) return null;
    final s = m.group(1)!.trim();
    // Branch on a condition that affects logic flow.
    if (s.length < 2) return null;
    return s;
  }


  static Future<String?> canonicalize(String pdfName) async {
    // Await an asynchronous operation.
    await ensureLoaded();
    return _aliasToCanonical[_norm(pdfName)];
  }

  
  static Future<TermInfo?> info(String canonical) async {
    // Await an asynchronous operation.
    await ensureLoaded();
    return _byCanonical[canonical];
  }
}
