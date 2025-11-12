import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:arva/services/pdf_extractor.dart';
import 'package:arva/models/lab_test.dart';

class MedicationAutomation {
  static late Interpreter _interpreter;
  static bool _loaded = false;

  /// 🔹 تحميل المودل TFLite مرة واحدة
  static Future<void> _loadModel() async {
    if (_loaded) return;
    _interpreter = await Interpreter.fromAsset('model.tflite');
    _loaded = true;
  }

  /// 🔹 العملية الكاملة
  static Future<void> runAutoMedicationPipeline(
      String patientId, String doctorId, String pdfPath) async {
    await _loadModel();

    // 1️⃣ استخراج جميع التحاليل من التقرير (باستخدام PdfExtractor)
    final List<LabTest> tests = await PdfExtractor.parse(pdfPath);
    print("✅ تم استخراج ${tests.length} تحليل من التقرير");

    // حولهم إلى خريطة لتسهيل البحث بالاسم
    final testMap = {for (var t in tests) t.name: t.value};

    // 2️⃣ جلب جميع أدوية المريض من Firestore
    final medsSnapshot = await FirebaseFirestore.instance
        .collection('patient_medications')
        .doc(patientId)
        .collection('drugs')
        .get();

    for (var med in medsSnapshot.docs) {
      final data = med.data();
      final String testName = data['test_name'];

      // إذا التقرير ما يحتوي هذا التحليل → تجاهله
      if (!testMap.containsKey(testName)) continue;

      final double testValue = testMap[testName] ?? 0.0;

      // 3️⃣ تحديث القيمة في نفس الدواء
      await med.reference.update({
        'value': testValue,
        'last_updated': FieldValue.serverTimestamp(),
      });

      // 4️⃣ التنبؤ بالجرعة الجديدة باستخدام المودل
      final prediction = await _predictDose(
        disease: data['disease'],
        drugName: data['drug_name'],
        testName: testName,
        testValue: testValue,
      );

      // 5️⃣ إنشاء اقتراح للطبيب للمراجعة قبل التطبيق
      await FirebaseFirestore.instance
          .collection('pending_suggestions')
          .doc(doctorId)
          .collection('notifications')
          .add({
        'patientId': patientId,
        'drug_name': data['drug_name'],
        'test_name': testName,
        'old_dosage': data['dosage'],
        'new_dosage': prediction['dosage'],
        'new_duration': prediction['duration'],
        'new_frequency': prediction['frequency'],
        'test_value': testValue,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("📤 تم إرسال اقتراح جديد للطبيب عن ${data['drug_name']}");
    }
  }

  /// 🧠 تشغيل المودل
  static Future<Map<String, String>> _predictDose({
    required String disease,
    required String drugName,
    required String testName,
    required double testValue,
  }) async {
    final input = [
      [testValue]
    ];
    final output = List.generate(1, (_) => List.filled(3, 0.0));

    _interpreter.run(input, output);

    final dosage = "${(output[0][0] * 100).round()} MG";
    final duration = "${(output[0][1] * 10).round()} weeks";
    final frequency = output[0][2] > 0.5 ? "Daily" : "Weekly";

    return {
      'dosage': dosage,
      'duration': duration,
      'frequency': frequency,
    };
  }
}