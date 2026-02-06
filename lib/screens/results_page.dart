import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'recommendation_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/pdf_extractor.dart';
import '../services/inference_service.dart';
import '../services/ui_mapping.dart';
import 'package:arva/screens/ai/update_medications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Send a local notification with a payload that lets the app route to the medication update flow.
Future<void> _showMedicationNotification({
  required String patientId,
  String? patientName,
}) async {
  final String name =
      (patientName != null && patientName.isNotEmpty) ? patientName : 'the patient';

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'medication_alerts', // ID للقناة
    'Medication Alerts', // اسم القناة
    channelDescription: 'Alerts for new predicted medication doses',
    importance: Importance.max,
    priority: Priority.high,
    color: Color(0xFF5FAAB1),
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  // Await an asynchronous operation.
  await _notificationsPlugin.show(
    1,
    '💊 Medication Update - $name',
    'New AI-predicted medication doses are ready for your review.',
    notificationDetails,
    payload: jsonEncode({
      'type': 'medication',
      'patientId': patientId,
      'patientName': name,
    }),
  );
}

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
  final Uint8List? pdfBytes;
  final String? patientId;
  final String? assetPdfPath;

  const ResultsPage({
    super.key,
    this.pdfBytes,
    this.patientId,
    this.assetPdfPath,
  });

  // Resolve which PDF asset path to use by checking explicit input, patient profile, then user profile.
  Future<String?> _resolveAssetPdfPath() async {
    // Prefer the explicitly provided asset path when available.
    if (assetPdfPath != null && assetPdfPath!.trim().isNotEmpty) {
      return assetPdfPath!;
    }

    // Fallback to current user id when no patient id is passed.
    final id = patientId ?? FirebaseAuth.instance.currentUser?.uid;
    // Branch on a condition that affects logic flow.
    if (id == null) return null;

    Future<String?> readFrom(String coll) async {
      final doc =
          // Await an asynchronous operation.
          await FirebaseFirestore.instance.collection(coll).doc(id).get();
      // Branch on a condition that affects logic flow.
      if (!doc.exists) return null;
      final data = doc.data();
      // Branch on a condition that affects logic flow.
      if (data == null) return null;

      final raw = (data['reportPdfName'] ??
          data['reportFileName'] ??
          data['reportAsset']) as String?;
      // Branch on a condition that affects logic flow.
      if (raw == null || raw.trim().isEmpty) return null;

      return raw.startsWith('assets/') ? raw : 'assets/$raw';
    }

    // Await an asynchronous operation.
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
                          // Navigate to another screen based on user action.
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
                    // Render from in-memory PDF bytes when provided; otherwise load from asset.
                    if (pdfBytes != null)
                      DynamicResultsFromBytes(pdfBytes: pdfBytes!)
                    else
                      // Load data asynchronously before rendering results.
                      FutureBuilder<String?>(
                        future: _resolveAssetPdfPath(),
                        builder: (context, snap) {
                          // Show a loader while async work completes.
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }
                          // Show an error state when async work fails.
                          if (snap.hasError) {
                            return _errorBox(
                                'can not read the file name ${snap.error}');
                          }
                          final assetPath = snap.data;
                          // Handle missing assets gracefully.
                          if (assetPath == null) {
                            return _errorBox('No test file for this patient');
                          }
                          // Render results from the resolved asset PDF.
                          return DynamicResultsFromAsset(
                            assetPdfPath: assetPath,
                            patientId: patientId,
                          );
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

  // Render a small error card for failed report loading.
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
    required this.valueNum,
    required this.loNum,
    required this.hiNum,
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
                child: const SizedBox(
                  width: 60,
                  height: 85,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: Color.fromARGB(255, 182, 199, 214),
                  ),
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

class _SegmentBar extends StatelessWidget {
  final double value, lo, hi;
  const _SegmentBar({required this.value, required this.lo, required this.hi});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;

      // Detect whether a valid reference range exists.
      final hasRange = lo.isFinite && hi.isFinite && hi > lo;
      // Branch on a condition that affects logic flow.
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
      // Branch on a condition that affects logic flow.
      if (value.isFinite) {
        // Branch on a condition that affects logic flow.
        if (value < start) start = value;
        // Branch on a condition that affects logic flow.
        if (value > end) end = value;
      }
      // Branch on a condition that affects logic flow.
      if (end <= start) end = start + 1;

      final total = end - start;
      final yellowW = ((lo - start) / total) * w;
      final greenW = ((hi - lo) / total) * w;
      final redW = w - yellowW - greenW;

      double indX = ((value - start) / total) * w;
      // Branch on a condition that affects logic flow.
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
  final String? patientId;

  const DynamicResultsFromAsset({
    super.key,
    required this.assetPdfPath,
    this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    // Load data asynchronously before rendering results.
    return FutureBuilder<List<_UiRow>>(
      future: _loadRows(assetPdfPath, patientId),
      builder: (context, snap) {
        // Show a loader while async work completes.
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // Show an error state when async work fails.
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
        // Branch on a condition that affects logic flow.
        if (rows.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No tests found in the report.'),
          );
        }
        return Column(
          children: [
            // Loop over a collection to apply logic.
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
                onTap: () {
                  // Navigate to another screen based on user action.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecommendationsScreen(
                        testName: r.testName,
                        value: r.valueNum,
                      ),
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

  static Future<List<_UiRow>> _loadRows(
    String assetPdfPath,
    String? patientId,
  ) async {
    debugPrint('📄 [Report] Starting parsing from asset PDF: $assetPdfPath');

    // Extract lab tests from the PDF report.
    final tests = await PdfExtractor.parseAsset(assetPdfPath);

    debugPrint('🧪 [Report] Extracted ${tests.length} lab tests from asset.');

    
    final targetId = patientId ?? FirebaseAuth.instance.currentUser?.uid;
    String? doctorId;
    String? patientName;

    // Branch on a condition that affects logic flow.
    if (targetId != null) {
      try {
        // Await an asynchronous operation.
        final patientDoc = await FirebaseFirestore.instance
            .collection('patient_profiles')
            .doc(targetId)
            .get();

        // Branch on a condition that affects logic flow.
        if (patientDoc.exists) {
          final data = patientDoc.data();
          doctorId = data?['assignedDoctorId'];
          patientName = data?['username'] ?? data?['name'];
        }

        debugPrint(
            '🤖 [Medication] Running medication model for patient $targetId using report: $assetPdfPath');

        // Run the medication model using extracted report values.
        await MedicationAutomation.runAutoMedicationPipeline(
          targetId, // patient id
          doctorId ?? "UNKNOWN_DOCTOR", // doctor id
          assetPdfPath, // report from assets
        );

        debugPrint(
            '✅ [Medication] Medication model executed using extracted report values.');

        
        // Notify the user that medication recommendations are ready.
        await _showMedicationNotification(
          patientId: targetId,
          patientName: patientName,
        );
      } catch (e) {
        debugPrint('⚠ [Medication] Failed to run medication model: $e');
      }
    } else {
      debugPrint(
          '⚠ [Medication] No current user found to run medication model.');
    }

   
    final out = <_UiRow>[];
    // Loop over a collection to apply logic.
    for (final t in tests) {
      // Classify the test result using the inference service.
      final res = await InferenceService.decide(t);
      // Detect whether a valid reference range exists.
      final hasRange =
          t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;

      out.add(_UiRow(
        testName: '(${t.code})',
        // Map inference output to a status label for UI.
        status: UiMapping.status(res.tri, res.source, hasRange: hasRange),
        value: _fmtVal(t.value),
        // Map inference output to a background color for UI.
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

class DynamicResultsFromBytes extends StatelessWidget {
  final Uint8List pdfBytes;
  const DynamicResultsFromBytes({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    // Load data asynchronously before rendering results.
    return FutureBuilder<List<_UiRow>>(
      future: _loadRows(pdfBytes),
      builder: (context, snap) {
        // Show a loader while async work completes.
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // Show an error state when async work fails.
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
        // Branch on a condition that affects logic flow.
        if (rows.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No tests found in the report.'),
          );
        }
        return Column(
          children: [
            // Loop over a collection to apply logic.
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
                onTap: () {
                  // Navigate to another screen based on user action.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecommendationsScreen(
                        testName: r.testName,
                        value: r.valueNum,
                      ),
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

  static Future<List<_UiRow>> _loadRows(Uint8List bytes) async {
    debugPrint(
        '📄 [Report] Starting parsing from in-memory PDF bytes (length: ${bytes.lengthInBytes}).');

    // Extract lab tests from the PDF report.
    final tests = await PdfExtractor.parseBytes(bytes);

    debugPrint('🧪 [Report] Extracted ${tests.length} lab tests from bytes.');

    final out = <_UiRow>[];
    // Loop over a collection to apply logic.
    for (final t in tests) {
      // Classify the test result using the inference service.
      final res = await InferenceService.decide(t);
      // Detect whether a valid reference range exists.
      final hasRange =
          t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;

      out.add(_UiRow(
        testName: '(${t.code})',
        // Map inference output to a status label for UI.
        status: UiMapping.status(res.tri, res.source, hasRange: hasRange),
        value: _fmtVal(t.value),
        // Map inference output to a background color for UI.
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
