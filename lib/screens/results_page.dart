import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'recommendation_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/pdf_extractor.dart';
import '../services/inference_service.dart';
import '../services/ui_mapping.dart';
import 'package:arva/screens/ai/update_medications.dart';


class AppColors {
  static const medicalBg = Color(0xFF5FAAB1);
  static const medicalCard = Color(0xFFF6FBFA);
  static const medicalDark = Color(0xFF173430);
  static const medicalGrey = Color(0xFF617D79);
  static const medicalSoftGrey = Color(0xFFF6F7F7);
  static const elevated = Color(0xFFF5475C);
  static const elevatedBg = Color(0x54F5475C);
  static const warning = Color(0xFFFDC944);
  static const warningBg = Color(0x52FDD777);
  static const normal = Color(0xFF2CB462);
  static const closeBtn = Color(0xFF4C6EA0);
  static const indicator = Color(0xFF006D77);
}

class ResultsPage extends StatelessWidget {
  /// إذا الدكتورة اخترت ملف من الجوال نمرّر الـ bytes مباشرة
  final Uint8List? pdfBytes;

  /// لو كنتِ دكتورة وجاية من ملف مريض، مرّري patientId لهذا المريض
  final String? patientId;

  /// (اختياري) لو حابة تمرّري مسار أصل (asset) مباشرة
  final String? assetPdfPath;

  const ResultsPage({
    super.key,
    this.pdfBytes,
    this.patientId,
    this.assetPdfPath,
  });

  /// إذا وصلنا patientId نستخدمه، وإلا نرجع لـ uid تبع المستخدم الحالي
  Future<String?> _resolveAssetPdfPath() async {
    // لو تم تمرير assetPdfPath مباشرة استخدمه فوراً
    if (assetPdfPath != null && assetPdfPath!.trim().isNotEmpty) {
      return assetPdfPath!;
    }

    final id = patientId ?? FirebaseAuth.instance.currentUser?.uid;
    if (id == null) return null;

    Future<String?> readFrom(String coll) async {
      final doc =
          await FirebaseFirestore.instance.collection(coll).doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;

      // غطّي كل الأسماء المحتملة للحقل
      final raw = (data['reportPdfName'] ??
          data['reportFileName'] ??
          data['reportAsset']) as String?;
      if (raw == null || raw.trim().isEmpty) return null;

      return raw.startsWith('assets/') ? raw : 'assets/$raw';
    }

    // جرّبي patient_profiles أولاً ثم users
    final p = await readFrom('patient_profiles') ?? await readFrom('users');
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.medicalBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.medicalCard,
                  borderRadius: BorderRadius.circular(38),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 40)
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 42,
                            height: 44,
                            decoration: const BoxDecoration(
                                color: AppColors.closeBtn,
                                shape: BoxShape.circle),
                            child: const Center(
                                child: Icon(Icons.close,
                                    color: Colors.white, size: 20)),
                          ),
                        ),
                        const Spacer(),
                        const Text('Results',
                            style: TextStyle(
                                color: Color(0xFF0E1B3D),
                                fontSize: 30,
                                fontWeight: FontWeight.w400)),
                        const Spacer(),
                        const SizedBox(width: 42),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // أولوية القراءة:
                    // 1) لو فيه pdfBytes: نقرأ مباشرة من الذاكرة
                    // 2) وإلا نحلّ مسار الأصل (assets) من فايرستور أو من الحقل الممرّر
                    if (pdfBytes != null)
                      DynamicResultsFromBytes(pdfBytes: pdfBytes!)
                    else
                      FutureBuilder<String?>(
                        future: _resolveAssetPdfPath(),
                        builder: (context, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snap.hasError) {
                            return _errorBox(
                                'can not read the file name ${snap.error}');
                          }
                          final assetPath = snap.data;
                          if (assetPath == null) {
                            return _errorBox('No test file for this patient');
                          }
                          return DynamicResultsFromAsset(
                              assetPdfPath: assetPath);
                        },
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.elevatedBg,
            borderRadius: BorderRadius.circular(12)),
        child:
            Text(msg, style: const TextStyle(color: AppColors.medicalDark)),
      );
}

class ResultCard extends StatelessWidget {
  final String testName;
  final String status;
  final String value;
  final Color backgroundColor;
  final String rangeMin;
  final String rangeMax;

  // === NEW: نمرّر القيم الرقمية للبار ===
  final double valueNum;
  final double loNum;
  final double hiNum;

  final VoidCallback? onTap;

  const ResultCard({
    super.key,
    required this.testName,
    required this.status,
    required this.value,
    required this.backgroundColor,
    required this.rangeMin,
    required this.rangeMax,
    required this.valueNum, // NEW
    required this.loNum, // NEW
    required this.hiNum, // NEW
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            
Positioned(
  right: -9,
  bottom: 14,
  child: InkWell(
    onTap: onTap,                   
    customBorder: const CircleBorder(),
    child: SizedBox(
      width: 60,
      height: 85,
      child: const Icon(Icons.arrow_forward_ios, size: 20, color: Color.fromARGB(255, 182, 199, 214)),
    ),
  ),
),

            const Positioned(
              left: 4,
              top: 6,
              child: SizedBox(
                  width: 37,
                  height: 45,
                  child: CustomPaint(painter: BloodDropPainter())),
            ),
            Positioned(
              right: 6,
              top: 8,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.medicalDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.24,
                ),
              ),
            ),
            // Labels (name + status) with ellipsis
            Positioned(
              left: 56,
              right: 84,
              top: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.medicalDark,
                      fontSize: 18,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.medicalGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.12,
                    ),
                  ),
                ],
              ),
            ),

            // === NEW: شريط ديناميكي مع قيمة/حدود ===
            Positioned(
              left: 8,
              right: 8,
              top: 84,
              child: _SegmentBar(value: valueNum, lo: loNum, hi: hiNum),
            ),
            Positioned(
              left: 56,
              right: 56,
              top: 104,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rangeMin,
                      style: const TextStyle(
                          color: AppColors.medicalGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                  Text(rangeMax,
                      style: const TextStyle(
                          color: AppColors.medicalGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === NEW: شريط أخضر يطابق refMin..refMax تماماً والمؤشر على القيمة فعلياً ===
class _SegmentBar extends StatelessWidget {
  final double value, lo, hi;
  const _SegmentBar({required this.value, required this.lo, required this.hi});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;

      final hasRange = lo.isFinite && hi.isFinite && hi > lo;
      if (!hasRange) {
        final y = w * 0.15,
            g = w * 0.70,
            r = w - y - g,
            indX = w * 0.5;
        return _buildBar(y, g, r, indX);
      }

      final margin = (hi - lo) * 0.25;
      double start = lo - margin;
      double end = hi + margin;
      if (value.isFinite) {
        if (value < start) start = value;
        if (value > end) end = value;
      }
      if (end <= start) end = start + 1;

      final total = end - start;
      final yellowW = ((lo - start) / total) * w;
      final greenW = ((hi - lo) / total) * w;
      final redW = w - yellowW - greenW;

      double indX = ((value - start) / total) * w;
      if (!indX.isFinite) indX = w * 0.5;
      indX = indX.clamp(0.0, w);

      return _buildBar(yellowW, greenW, redW, indX);
    });
  }

  Widget _buildBar(double yellowW, double greenW, double redW, double indX) {
    return SizedBox(
      height: 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Container(
                width: yellowW,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(999)),
                ),
              ),
              Container(width: greenW, height: 6, color: AppColors.normal),
              Container(
                width: redW,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius:
                      BorderRadius.horizontal(right: Radius.circular(999)),
                ),
              ),
            ],
          ),
          Positioned(
            top: -6,
            left: indX - 6,
            child: const SizedBox(
                width: 12,
                height: 10,
                child: CustomPaint(painter: TrianglePainter())),
          ),
        ],
      ),
    );
  }
}

class BloodDropPainter extends CustomPainter {
  const BloodDropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()..color = AppColors.elevated..style = PaintingStyle.fill;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.74, h * 0.22, w, h * 0.53, w, h * 0.73)
      ..cubicTo(w, h * 0.92, w * 0.78, h, w * 0.5, h)
      ..cubicTo(w * 0.22, h, 0, h * 0.92, 0, h * 0.73)
      ..cubicTo(0, h * 0.53, w * 0.26, h * 0.22, w * 0.5, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrianglePainter extends CustomPainter {
  const TrianglePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()..color = AppColors.indicator..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DynamicResultsFromAsset extends StatelessWidget {
  final String assetPdfPath;
  const DynamicResultsFromAsset({super.key, required this.assetPdfPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_UiRow>>(
      future: _loadRows(assetPdfPath),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.elevatedBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${snap.error}',
                style: const TextStyle(color: AppColors.medicalDark)),
          );
        }
        final rows = snap.data ?? const <_UiRow>[];
        if (rows.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No tests found in the report.'),
          );
        }
        return Column(
          children: [
            for (final r in rows) ...[
              ResultCard(
                testName: r.testName,
                status: r.status,
                value: r.value,
                backgroundColor: r.bg,
                rangeMin: r.minLabel,
                rangeMax: r.maxLabel,
                valueNum: r.valueNum, // NEW
                loNum: r.loNum, // NEW
                hiNum: r.hiNum, // NEW
                onTap: () {
    // مبدئياً نفتح صفحة الريكومنديشن العامة.
    // لاحقًا تقدري تمرّري params وتخصصي المحتوى لكل تحليل.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecommendationsScreen(),
      ),
    );
  },
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
static Future<List<_UiRow>> _loadRows(String assetPdfPath, {String? patientId}) async {
  final tests = await PdfExtractor.parseAsset(assetPdfPath);

  // 🧠 تحديد هوية المستخدم
  final targetId = patientId ?? FirebaseAuth.instance.currentUser?.uid;
  String? doctorId;

  if (targetId != null) {
    try {
      // 🔹 نجيب Doctor ID من ملف المريض
      final patientDoc = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(targetId)
          .get();

      if (patientDoc.exists) {
        doctorId = patientDoc.data()?['assignedDoctorId'];
      }

      
      await MedicationAutomation.runAutoMedicationPipeline(
        targetId,                          // معرف المريض
        doctorId ?? "UNKNOWN_DOCTOR",      // معرف الدكتور
        assetPdfPath,                      // التقرير من الـ assets
      );

      debugPrint('✅ تم تشغيل موديل الأدوية بناءً على القيم المستخرجة من التقرير');
    } catch (e) {
      debugPrint('⚠ فشل تشغيل موديل الأدوية: $e');
    }
  } else {
    debugPrint('⚠ لم يتم العثور على مستخدم حالي لتشغيل المودل');
  }

  // 🎨 بناء واجهة عرض نتائج التحاليل نفسها
  final out = <_UiRow>[];
  for (final t in tests) {
    final res = await InferenceService.decide(t);
    final hasRange =
        t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;

    out.add(_UiRow(
      testName: '(${t.code})',
      status: UiMapping.status(res.tri, res.source, hasRange: hasRange),
      value: _fmtVal(t.value),
      bg: UiMapping.bg(res.tri, res.source),
      minLabel: hasRange ? _fmtRange(t.refMin, t.code) : '',
      maxLabel: hasRange ? _fmtRange(t.refMax, t.code) : '',
      valueNum: t.value,
      loNum: hasRange ? t.refMin : double.nan,
      hiNum: hasRange ? t.refMax : double.nan,
    ));
  }
  return out;
}

  static String _fmtVal(double v) =>
      v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  static String _fmtRange(double v, String code) {
    // بدون وحدات
    return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
  }
}

class DynamicResultsFromBytes extends StatelessWidget {
  final Uint8List pdfBytes;
  const DynamicResultsFromBytes({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_UiRow>>(
      future: _loadRows(pdfBytes),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.elevatedBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${snap.error}',
                style: const TextStyle(color: AppColors.medicalDark)),
          );
        }
        final rows = snap.data ?? const <_UiRow>[];
        if (rows.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No tests found in the report.'),
          );
        }
        return Column(
          children: [
            for (final r in rows) ...[
              ResultCard(
                testName: r.testName,
                status: r.status,
                value: r.value,
                backgroundColor: r.bg,
                rangeMin: r.minLabel,
                rangeMax: r.maxLabel,
                valueNum: r.valueNum,
                loNum: r.loNum,
                hiNum: r.hiNum,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  static Future<List<_UiRow>> _loadRows(Uint8List bytes) async {
    
    final tests = await PdfExtractor.parseBytes(bytes);


    final out = <_UiRow>[];
    for (final t in tests) {
      final res = await InferenceService.decide(t);
      final hasRange =
          t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;

      out.add(_UiRow(
        testName: '(${t.code})',
        status: UiMapping.status(res.tri, res.source, hasRange: hasRange),
        value: _fmtVal(t.value),
        bg: UiMapping.bg(res.tri, res.source),
        minLabel: hasRange ? _fmtRange(t.refMin, t.code) : '',
        maxLabel: hasRange ? _fmtRange(t.refMax, t.code) : '',
        valueNum: t.value,
        loNum: hasRange ? t.refMin : double.nan,
        hiNum: hasRange ? t.refMax : double.nan,
      ));
    }
    return out;
  }

  static String _fmtVal(double v) =>
      v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  static String _fmtRange(double v, String code) {
    return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
  }
}

class _UiRow {
  final String testName, status, value, minLabel, maxLabel;
  final Color bg;

  // NEW: أرقام للبار
  final double valueNum, loNum, hiNum;

  _UiRow({
    required this.testName,
    required this.status,
    required this.value,
    required this.bg,
    required this.minLabel,
    required this.maxLabel,
    required this.valueNum,
    required this.loNum,
    required this.hiNum,
  });
}
