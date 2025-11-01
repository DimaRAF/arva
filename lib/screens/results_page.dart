import 'package:flutter/material.dart';
//import 'recommendation_page.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import '../models/lab_test.dart';
import '../services/pdf_extractor.dart';
import '../services/inference_service.dart';
import '../services/ui_mapping.dart';



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
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // تم إزالة SafeArea من هنا ووضعها داخل Scaffold
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
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: Offset(0, 0),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        
                        GestureDetector(
                          onTap: () {
                            
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 42,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.closeBtn,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        const Text(
                          'Results',
                          style: TextStyle(
                            color: Color(0xFF0E1B3D),
                            fontSize: 30,
                            height: 32 / 30,
                            letterSpacing: -1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 42),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const DynamicResultsFromAsset(assetPdfPath: 'assets/fileName.pdf'),
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
}

class ResultCard extends StatelessWidget {
  final String testName;
  final String status;
  final String value;
  final Color backgroundColor;
  final String rangeMin;
  final String rangeMax;
  final double indicatorPosition; 
  final VoidCallback? onTap;

  const ResultCard({
    super.key,
    required this.testName,
    required this.status,
    required this.value,
    required this.backgroundColor,
    required this.rangeMin,
    required this.rangeMax,
    required this.indicatorPosition,
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
          // Icon
          const Positioned(
            left: 4,
            top: 6,
            child: SizedBox(width: 37, height: 45, child: CustomPaint(painter: BloodDropPainter())),
          ),

          // Value
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

          // Labels
          Positioned(
            left: 56,
            top: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  testName,
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

          // Progress and indicator
          Positioned(
            left: 8,
            right: 8,
            top: 84,
            child: _SegmentBar(indicator: indicatorPosition),
          ),

          // Range text
          Positioned(
            left: 56,
            right: 56,
            top: 104,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rangeMin, style: const TextStyle(color: AppColors.medicalGrey, fontSize: 10, fontWeight: FontWeight.w500)),
                Text(rangeMax, style: const TextStyle(color: AppColors.medicalGrey, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  final double indicator; // 0..1
  const _SegmentBar({required this.indicator});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      
      final yellowW = w * 0.086;
      final greenW = w * 0.618;
      final redW = w * 0.296;
      final indX = (w * indicator).clamp(0.0, w);

      return SizedBox(
        height: 12,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Container(width: yellowW, height: 6, decoration: const BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.horizontal(left: Radius.circular(999)))),
                Container(width: greenW, height: 6, color: AppColors.normal),
                Container(width: redW, height: 6, decoration: const BoxDecoration(color: AppColors.elevated, borderRadius: BorderRadius.horizontal(right: Radius.circular(999)))),
              ],
            ),
            Positioned(
              top: -6,
              left: indX - 6,
              child: const SizedBox(width: 12, height: 10, child: CustomPaint(painter: TrianglePainter())),
            ),
          ],
        ),
      );
    });
  }
}

class BloodDropPainter extends CustomPainter {
  const BloodDropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.elevated..style = PaintingStyle.fill;
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
    final paint = Paint()..color = AppColors.indicator..style = PaintingStyle.fill;
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
              color: AppColors.elevatedBg, borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${snap.error}', style: const TextStyle(color: AppColors.medicalDark)),
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
                indicatorPosition: r.indicator,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  // === Helpers ===
  static Future<List<_UiRow>> _loadRows(String assetPdfPath) async {
    // Parse PDF مباشرة من الـ assets
final tests = await PdfExtractor.parseAsset(assetPdfPath);


    // 3) شغّلي المودل لكل تحليل، وابني صفوف العرض
    final out = <_UiRow>[];
for (final t in tests) {
  final res = await InferenceService.decide(t); // res.tri & res.source
  final hasRange = t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;

  out.add(_UiRow(
    testName: '(${t.code})',
    status: UiMapping.status(res.tri, res.source, hasRange: hasRange),
    value: _fmtVal(t.value),
    bg: UiMapping.bg(res.tri, res.source),
    minLabel: hasRange ? _fmtRange(t.refMin, t.code) : '',
    maxLabel: hasRange ? _fmtRange(t.refMax, t.code) : '',
    indicator: UiMapping.indicator(t.value, t.refMin, t.refMax),
  ));
}

    return out;
  }

  static String _fmtVal(double v) =>
      v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  static String _fmtRange(double v, String code) {
    final u = code.toUpperCase();
    if (u == 'WBC') return '${v.toStringAsFixed(0)}×10^9/L';
    if (u == 'MCV') return '${v.toStringAsFixed(0)} fL';
    if (u == 'MCH') return '${v.toStringAsFixed(0)} pg';
    if (u == 'HCT') return v.toStringAsFixed(0);
    return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
  }
}

// نموذج بيانات العرض (نفس شكل الكروت عندك)
class _UiRow {
  final String testName, status, value, minLabel, maxLabel;
  final double indicator;
  final Color bg;
  _UiRow({
    required this.testName,
    required this.status,
    required this.value,
    required this.bg,
    required this.minLabel,
    required this.maxLabel,
    required this.indicator,
  });
}
