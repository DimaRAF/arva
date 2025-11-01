import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;

class TermInfo {
  final String canonical;        // من عمود medical term (لا تغيّريه)
  final double? refMin;          // Lowest_Normal
  final double? refMax;          // Highest_Normal
  final String unit;             // Unit
  const TermInfo({required this.canonical, this.refMin, this.refMax, required this.unit});
}

class TermDictionary {
  static bool _loaded = false;
  static final Map<String, TermInfo> _byCanonical = {};    // "WBC" -> info
  static final Map<String, String> _aliasToCanonical = {}; // "WHITE BLOOD CELLS" -> "WBC"

  /// استدعيها مرّة قبل الاستخدام (مثلًا في initState لأول صفحة)
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final bytes = await rootBundle.load('assets/medical_term_full.xlsx');
    final excel = Excel.decodeBytes(bytes.buffer.asUint8List());

    final sheet = excel.tables[excel.tables.keys.first]!;
    // رؤوس الأعمدة بالضبط كما أرسلتي (نقرأ case-insensitive)
    final headers = sheet.rows.first
        .map((c) => (c?.value?.toString().trim() ?? '').toLowerCase())
        .toList();

    final int idxName  = headers.indexOf('medical term');
    final int idxLo    = headers.indexOf('lowest_normal');
    final int idxHi    = headers.indexOf('highest_normal');
    final int idxUnit  = headers.indexOf('unit');

    if (idxName < 0) { throw Exception('❌ Column "medical term" not found in Excel'); }

    for (int r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      final String name = _s(row, idxName);
      if (name.isEmpty) continue;

      final double? lo  = _d(row, idxLo);
      final double? hi  = _d(row, idxHi);
      final String unit = _s(row, idxUnit);

      final canon = _canon(name);
      final info = TermInfo(canonical: canon, refMin: lo, refMax: hi, unit: unit);
      _byCanonical[canon] = info;

      // aliases الأساسية: نفس الاسم بصيغ مختلفة (upper/strip) + بدون أقواس/زخارف
      for (final alias in _generateAliases(name)) {
        _aliasToCanonical[alias] = canon;
      }
      // أضف أيضًا الصيغة المختصرة إن كانت موجودة ضمن الاسم (مثل WBC داخل "Total Leucocytic Count (WBC)")
      final short = _extractShort(name);
      if (short != null) {
        _aliasToCanonical[_norm(short)] = canon;
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

  static String _canon(String s) => s.trim();    // نستخدم الاسم كما هو من العمود
  static String _norm(String s) => s
      .toUpperCase()
      .replaceAll(RegExp(r'[\t\r\n]'), ' ')
      .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Iterable<String> _generateAliases(String name) {
    final aliases = <String>{};
    aliases.add(_norm(name));              // النسخة المطَبَّعة
    aliases.add(_norm(name.replaceAll(RegExp(r'\(.*?\)'), ''))); // بدون أقواس
    return aliases.where((e) => e.isNotEmpty);
  }

  static String? _extractShort(String name) {
    final m = RegExp(r'\(([A-Za-z0-9+\- ]{2,15})\)').firstMatch(name);
    if (m == null) return null;
    final s = m.group(1)!.trim();
    if (s.length < 2) return null;
    return s;
  }

  /// يحوّل اسم من الـPDF إلى الاسم القياسي من عمود medical term (أو null إذا ما وجد)
  static Future<String?> canonicalize(String pdfName) async {
    await ensureLoaded();
    return _aliasToCanonical[_norm(pdfName)];
  }

  /// يرجّع معلومات التحليل حسب الاسم القياسي (نفس عمود medical term)
  static Future<TermInfo?> info(String canonical) async {
    await ensureLoaded();
    return _byCanonical[canonical];
  }
}
