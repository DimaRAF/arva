import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:arva/services/pdf_extractor.dart';
import 'package:arva/models/lab_test.dart';
// 🔔 NEW
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MedicationAutomation {
  static late Interpreter _interpreter;
  static bool _loaded = false;

  // ==== metadata من ملفات الـ JSON ====
  static Map<String, int>? _diseaseToId;
  static Map<String, int>? _drugToId;
  static Map<String, int>? _testToId;

  static Map<int, String>? _dosageLabels;
  static Map<int, String>? _durationLabels;
  static Map<int, String>? _frequencyLabels;

  static double? _minValue;
  static double? _maxValue;

  // أي output slot (0/1/2) هو dosage/duration/freq
  static int? _dosageOutSlot;
  static int? _durationOutSlot;
  static int? _freqOutSlot;

  // 🔔 NEW: بلجن الإشعارات
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 🔔 NEW: دالة الإشعار عند وجود تنبؤ جديد
  static Future<void> _showMedicationNotification({
    required String patientId,
  }) async {
    String patientName = 'the patient';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(patientId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          patientName =
              (data['username'] ?? data['name'] ?? patientName).toString();
        }
      }
    } catch (e) {
      print('⚠ Failed to load patient name for notification: $e');
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medication_alerts',
      'Medication Alerts',
      channelDescription: 'Alerts for new predicted medication doses',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      1,
      '💊 Medication Update - $patientName',
      'New AI-predicted medication doses are ready for review.',
      notificationDetails,
      payload: jsonEncode({
        'type': 'medication',
        'patientId': patientId,
        'patientName': patientName,
      }),
    );
  }

  /// 🔹 تحميل المودل + ملفات JSON مرة واحدة
  static Future<void> _loadModel() async {
    if (_loaded) return;

    // 1) تحميل المودل
    _interpreter =
        await Interpreter.fromAsset('assets/medication_model/model.tflite');

    // 2) تحميل label_encoders.json
    final labelStr = await rootBundle
        .loadString('assets/medication_model/label_encoders.json');
    final labelJson = jsonDecode(labelStr) as Map<String, dynamic>;

    Map<String, int> buildReverse(Map<String, dynamic> m) {
      final out = <String, int>{};
      m.forEach((k, v) {
        if (v != null) {
          out[v as String] = int.parse(k);
        }
      });
      return out;
    }

    _diseaseToId =
        buildReverse(Map<String, dynamic>.from(labelJson['Disease']));
    _drugToId =
        buildReverse(Map<String, dynamic>.from(labelJson['Drug_Name']));
    _testToId =
        buildReverse(Map<String, dynamic>.from(labelJson['test_name']));

    // 3) تحميل target_encoders.json
    final targetStr = await rootBundle
        .loadString('assets/medication_model/target_encoders.json');
    final targetJson = jsonDecode(targetStr) as Map<String, dynamic>;

    Map<int, String> buildTarget(Map<String, dynamic> m) {
      final out = <int, String>{};
      m.forEach((k, v) {
        if (v != null) {
          out[int.parse(k)] = v.toString();
        }
      });
      return out;
    }

    _dosageLabels =
        buildTarget(Map<String, dynamic>.from(targetJson['Dosage']));
    _durationLabels =
        buildTarget(Map<String, dynamic>.from(targetJson['Duration']));
    _frequencyLabels =
        buildTarget(Map<String, dynamic>.from(targetJson['Frequency']));

    // 4) تحميل scaler.json
    final scalerStr = await rootBundle
        .loadString('assets/medication_model/scaler (1).json');
    final scalerJson = jsonDecode(scalerStr) as Map<String, dynamic>;
    final minList = (scalerJson['min'] as List).cast<num>();
    final maxList = (scalerJson['max'] as List).cast<num>();
    _minValue = minList.first.toDouble();
    _maxValue = maxList.first.toDouble();

    // 5) تحديد أي output هو Dosage/Duration/Freq حسب عدد الكلاسات
    final nDosage = _dosageLabels!.length;
    final nDuration = _durationLabels!.length;
    final nFreq = _frequencyLabels!.length;

    // بدلاً من getOutputTensorCount()
    final outTensors = _interpreter.getOutputTensors();

    for (int i = 0; i < outTensors.length; i++) {
      final shape = outTensors[i].shape; // List<int>
      final numClasses = shape.last;
      if (numClasses == nDosage) {
        _dosageOutSlot = i;
      } else if (numClasses == nDuration) {
        _durationOutSlot = i;
      } else if (numClasses == nFreq) {
        _freqOutSlot = i;
      }
    }

    print("🔎 Output mapping:");
    print(
        "nDosage=$nDosage, nDuration=$nDuration, nFreq=$nFreq → dosageSlot=$_dosageOutSlot, durationSlot=$_durationOutSlot, freqSlot=$_freqOutSlot");

    if (_dosageOutSlot == null ||
        _durationOutSlot == null ||
        _freqOutSlot == null) {
      throw Exception("❌ لم يتم التعرف على مخارج المودل!");
    }

    _loaded = true;
  }

  /// 🔹 العملية الكاملة: تشغيل المودل وتخزين التنبؤ في pending_*
  static Future<void> runAutoMedicationPipeline(
    String patientId,
    String doctorId,
    String pdfAssetPath,
  ) async {
    await _loadModel();

    // 1️⃣ استخراج التحاليل من التقرير
    final List<LabTest> tests = await PdfExtractor.parseAsset(pdfAssetPath);
    print("✅ تم استخراج ${tests.length} تحليل من التقرير (مودل الأدوية)");

    // خريطة من اسم التحليل → قيمته من التقرير
    final Map<String, double> testMap = {
      for (var t in tests) t.name: t.value,
    };

    // 2️⃣ جلب أدوية المريض
    final medsSnapshot = await FirebaseFirestore.instance
        .collection('patient_profiles')
        .doc(patientId)
        .collection('medications')
        .get();

    print("📄 تم العثور على ${medsSnapshot.docs.length} دواء لهذا المريض");

    // 🔔 NEW: فلاغ لتحديد إذا فيه أي دواء تم تحديثه
    bool anyUpdated = false;

    for (final med in medsSnapshot.docs) {
      final data = med.data();

      final String? disease = data['disease'] as String?;
      final String? drugName = data['drug_name'] as String?;
      final String? testName = data['test_name'] as String?;

      if (disease == null || drugName == null || testName == null) {
        print(
            "⚠ دواء بدون بيانات كافية (disease / drug_name / test_name) → يتم تجاهله. id=${med.id}");
        continue;
      }

      // 🔹 القيمة من التقرير (إن وجدت)
      final double? pdfValue = testMap[testName];

      // 🔹 آخر قيمة محفوظة في الداتا بيز (مثلاً من شاشة الفايتل ساين)
      final num? dbLastNum = data['last_value'] as num?;
      final double? dbLastValue = dbLastNum?.toDouble();

      // 🔹 القيمة النهائية التي سيستخدمها المودل
      double? effectiveValue;
      String valueSource = 'none';

      if (pdfValue != null) {
        effectiveValue = pdfValue;
        valueSource = 'PDF';
      } else if (dbLastValue != null) {
        effectiveValue = dbLastValue;
        valueSource = 'DB(last_value)';
      }

      if (effectiveValue == null) {
        print(
            "ℹ لا توجد قيمة (لا من التقرير ولا من last_value) للتحليل $testName → تجاهل الدواء $drugName");
        continue;
      }

      final double testValue = effectiveValue;
      print(
          "🔍 دواء: $drugName | Test: $testName = $testValue (source=$valueSource)");

      // 3️⃣ التنبؤ باستخدام المودل (القيمة المستخدمة هي من الداتا بيز منطقياً)
      final prediction = await _predictDose(
        disease: disease,
        drugName: drugName,
        testName: testName,
        testValue: testValue,
      );

      print("🤖 Prediction for $drugName → "
          "dosage=${prediction['dosage']}, "
          "duration=${prediction['duration']}, "
          "frequency=${prediction['frequency']}");

      // 4️⃣ حفظ التنبؤ في pending_* + last_value + status = "Pending"
      await med.reference.update({
        'pending_dosage': prediction['dosage'],
        'pending_duration': prediction['duration'],
        'pending_frequency': prediction['frequency'],
        'pending_test_name': testName,
        'pending_test_value': testValue,
        'pending_updated_at': FieldValue.serverTimestamp(),

        // ✅ آخر قيمة للتحليل لهذا الدواء (سواء جت من التقرير أو من قبل)
        'last_value': testValue,
        'status': 'Pending', // الدكتور لسه ما وافق

        'last_updated': FieldValue.serverTimestamp(),
      });

      anyUpdated = true;

      print(
          "💾 تم حفظ التنبؤ في pending_* داخل patient_profiles/$patientId/medications/${med.id}");
    }

    // 🔔 NEW: لو فيه تنبؤات جديدة → إرسال إشعار
    if (anyUpdated) {
      await _showMedicationNotification(patientId: patientId);
    }

    print("✅ انتهى تشغيل مودل الأدوية (تم التحديث في pending_* فقط)");
  }

  static Future<Map<String, String>> _predictDose({
    required String disease,
    required String drugName,
    required String testName,
    required double testValue,
  }) async {
    await _loadModel();

    // 1) تحويل النصوص إلى IDs حسب label_encoders.json
    final diseaseId = _diseaseToId![disease];
    final drugId = _drugToId![drugName];
    final testId = _testToId![testName];

    if (diseaseId == null || drugId == null || testId == null) {
      throw Exception(
          "القيم (disease/drug_name/test_name) غير متطابقة مع label_encoders.json "
          "→ تأكدي من نفس الإملاء الموجود في ملف الإكسل.");
    }

    // 2) تطبيع قيمة التحليل بنفس scaler.json
    final minV = _minValue!;
    final maxV = _maxValue!;
    final norm =
        ((testValue - minV) / (maxV - minV)).clamp(0.0, 1.0).toDouble();

    // 3) تجهيز المدخل (1, 4)
    final input = [
      [diseaseId.toDouble(), drugId.toDouble(), testId.toDouble(), norm]
    ];

    // 4) تجهيز مخرجات بثلاث رؤوس (Dosage / Duration / Frequency)
    final dosageCount = _dosageLabels!.length;
    final durationCount = _durationLabels!.length;
    final freqCount = _frequencyLabels!.length;

    final dosageOutput =
        List.generate(1, (_) => List.filled(dosageCount, 0.0));
    final durationOutput =
        List.generate(1, (_) => List.filled(durationCount, 0.0));
    final freqOutput =
        List.generate(1, (_) => List.filled(freqCount, 0.0));

    if (_dosageOutSlot == null ||
        _durationOutSlot == null ||
        _freqOutSlot == null) {
      throw Exception("⚠ مخرجات المودل غير مهيأة (output slots null)");
    }

    final outputs = <int, Object>{
      _dosageOutSlot!: dosageOutput,
      _durationOutSlot!: durationOutput,
      _freqOutSlot!: freqOutput,
    };

    _interpreter.runForMultipleInputs([input], outputs);

    // 5) argmax لكل مخرج
    int argMax(List<double> list) {
      var maxIdx = 0;
      var maxVal = list[0];
      for (var i = 1; i < list.length; i++) {
        if (list[i] > maxVal) {
          maxVal = list[i];
          maxIdx = i;
        }
      }
      return maxIdx;
    }

    final dosageIdx =
        argMax((outputs[_dosageOutSlot!] as List<List<double>>)[0]);
    final durationIdx =
        argMax((outputs[_durationOutSlot!] as List<List<double>>)[0]);
    final freqIdx =
        argMax((outputs[_freqOutSlot!] as List<List<double>>)[0]);

    final dosageLabel = _dosageLabels![dosageIdx] ?? '';
    final durationLabel = _durationLabels![durationIdx] ?? '';
    final freqLabel = _frequencyLabels![freqIdx] ?? '';

    return {
      'dosage': dosageLabel,
      'duration': durationLabel,
      'frequency': freqLabel,
    };
  }

  /// ✅ الدكتور يعتمد التنبؤ → ينقل القيم من pending_* إلى الحقول الأساسية
  static Future<void> approveMedicationPrediction({
    required String patientId,
    required String medicationId,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('patient_profiles')
        .doc(patientId)
        .collection('medications')
        .doc(medicationId);

    final snap = await ref.get();
    if (!snap.exists) {
      print("❌ دواء غير موجود للموافقة عليه");
      return;
    }

    final data = snap.data()!;
    final pendingDosage = data['pending_dosage'];
    final pendingDuration = data['pending_duration'];
    final pendingFrequency = data['pending_frequency'];
    final pendingTestValue = data['pending_test_value'];

    if (pendingDosage == null &&
        pendingDuration == null &&
        pendingFrequency == null) {
      print("ℹ لا توجد قيم pending_* لاعتمادها");
      return;
    }

    await ref.update({
      'dosage': pendingDosage,
      'duration': pendingDuration,
      'frequency': pendingFrequency,
      'last_value': pendingTestValue ?? data['last_value'],

      'status': 'Approved',

      'pending_dosage': null,
      'pending_duration': null,
      'pending_frequency': null,
      'pending_test_name': null,
      'pending_test_value': null,
      'pending_updated_at': null,

      'last_updated': FieldValue.serverTimestamp(),
    });

    print(
        "✅ تم اعتماد التنبؤ ونقله إلى الحقول الأساسية (dosage/duration/frequency)");
  }
}
