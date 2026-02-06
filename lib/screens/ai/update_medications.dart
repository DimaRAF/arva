import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:arva/services/pdf_extractor.dart';
import 'package:arva/models/lab_test.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MedicationAutomation {
  static late Interpreter _interpreter;
  static bool _loaded = false;

  static Map<String, int>? _diseaseToId;
  static Map<String, int>? _drugToId;
  static Map<String, int>? _testToId;

  static Map<int, String>? _dosageLabels;
  static Map<int, String>? _durationLabels;
  static Map<int, String>? _frequencyLabels;

  static double? _minValue;
  static double? _maxValue;


  static int? _dosageOutSlot;
  static int? _durationOutSlot;
  static int? _freqOutSlot;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

 
  static Future<void> _showMedicationNotification({
    required String patientId,
  }) async {
    String patientName = 'the patient';

    try {
      // Await an asynchronous operation.
      final doc = await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(patientId)
          .get();

      // Branch on a condition that affects logic flow.
      if (doc.exists) {
        final data = doc.data();
        // Branch on a condition that affects logic flow.
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

    // Await an asynchronous operation.
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

  static Future<void> _loadModel() async {
    // Branch on a condition that affects logic flow.
    if (_loaded) return;

 
    _interpreter =
        // Await an asynchronous operation.
        await Interpreter.fromAsset('assets/medication_model/model.tflite');

   
    // Await an asynchronous operation.
    final labelStr = await rootBundle
        .loadString('assets/medication_model/label_encoders.json');
    final labelJson = jsonDecode(labelStr) as Map<String, dynamic>;

    Map<String, int> buildReverse(Map<String, dynamic> m) {
      final out = <String, int>{};
      m.forEach((k, v) {
        // Branch on a condition that affects logic flow.
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

    // Await an asynchronous operation.
    final targetStr = await rootBundle
        .loadString('assets/medication_model/target_encoders.json');
    final targetJson = jsonDecode(targetStr) as Map<String, dynamic>;

    Map<int, String> buildTarget(Map<String, dynamic> m) {
      final out = <int, String>{};
      m.forEach((k, v) {
        // Branch on a condition that affects logic flow.
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

 
    // Await an asynchronous operation.
    final scalerStr = await rootBundle
        .loadString('assets/medication_model/scaler (1).json');
    final scalerJson = jsonDecode(scalerStr) as Map<String, dynamic>;
    final minList = (scalerJson['min'] as List).cast<num>();
    final maxList = (scalerJson['max'] as List).cast<num>();
    _minValue = minList.first.toDouble();
    _maxValue = maxList.first.toDouble();

   
    final nDosage = _dosageLabels!.length;
    final nDuration = _durationLabels!.length;
    final nFreq = _frequencyLabels!.length;

   
    final outTensors = _interpreter.getOutputTensors();

    // Loop over a collection to apply logic.
    for (int i = 0; i < outTensors.length; i++) {
      final shape = outTensors[i].shape; // List<int>
      final numClasses = shape.last;
      // Branch on a condition that affects logic flow.
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

    // Branch on a condition that affects logic flow.
    if (_dosageOutSlot == null ||
        _durationOutSlot == null ||
        _freqOutSlot == null) {
      throw Exception("❌ لم يتم التعرف على مخارج المودل!");
    }

    _loaded = true;
  }

  
  static Future<void> runAutoMedicationPipeline(
    String patientId,
    String doctorId,
    String pdfAssetPath,
  ) async {
    // Await an asynchronous operation.
    await _loadModel();
    // Await an asynchronous operation.
    final List<LabTest> tests = await PdfExtractor.parseAsset(pdfAssetPath);
    print("✅ Extracted ${tests.length} lab tests from the report (medication model).");


    final Map<String, double> testMap = {
      // Loop over a collection to apply logic.
      for (var t in tests) t.name: t.value,
    };
    // Await an asynchronous operation.
    final medsSnapshot = await FirebaseFirestore.instance
        .collection('patient_profiles')
        .doc(patientId)
        .collection('medications')
        .get();

    print("📄 Found ${medsSnapshot.docs.length} medications for this patient.");

    bool anyUpdated = false;

    // Loop over a collection to apply logic.
    for (final med in medsSnapshot.docs) {
      final data = med.data();

      final String? disease = data['disease'] as String?;
      final String? drugName = data['drug_name'] as String?;
      final String? testName = data['test_name'] as String?;

      // Branch on a condition that affects logic flow.
      if (disease == null || drugName == null || testName == null) {
        print(
            "⚠ Medication has missing data (disease / drug_name / test_name) → skipping. id=${med.id}");
        continue;
      }
      final double? pdfValue = testMap[testName];
      final num? dbLastNum = data['last_value'] as num?;
      final double? dbLastValue = dbLastNum?.toDouble();

      double? effectiveValue;
      String valueSource = 'none';

      // Branch on a condition that affects logic flow.
      if (pdfValue != null) {
        effectiveValue = pdfValue;
        valueSource = 'PDF';
      } else if (dbLastValue != null) {
        effectiveValue = dbLastValue;
        valueSource = 'DB(last_value)';
      }

      // Branch on a condition that affects logic flow.
      if (effectiveValue == null) {
        print(
            "ℹ No value found (neither from report nor last_value) for test $testName → skipping medication $drugName");
        continue;
      }

      final double testValue = effectiveValue;
      print(
          "🔍 Medication: $drugName | Test: $testName = $testValue (source=$valueSource)");

      
      // Await an asynchronous operation.
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

      // Await an asynchronous operation.
      await med.reference.update({
        'pending_dosage': prediction['dosage'],
        'pending_duration': prediction['duration'],
        'pending_frequency': prediction['frequency'],
        'pending_test_name': testName,
        'pending_test_value': testValue,
        'pending_updated_at': FieldValue.serverTimestamp(),

        'last_value': testValue,
        'status': 'Pending',

        'last_updated': FieldValue.serverTimestamp(),
      });

      anyUpdated = true;

      print(
          "💾 Saved prediction into pending_* at patient_profiles/$patientId/medications/${med.id}");
    }

    
    // Branch on a condition that affects logic flow.
    if (anyUpdated) {
      // Notify the user that medication recommendations are ready.
      await _showMedicationNotification(patientId: patientId);
    }

    print("✅ Medication model run completed (pending_* updated only)");
  }

  static Future<Map<String, String>> _predictDose({
    required String disease,
    required String drugName,
    required String testName,
    required double testValue,
  }) async {
    // Await an asynchronous operation.
    await _loadModel();

   
    final diseaseId = _diseaseToId![disease];
    final drugId = _drugToId![drugName];
    final testId = _testToId![testName];

    // Branch on a condition that affects logic flow.
    if (diseaseId == null || drugId == null || testId == null) {
      throw Exception(
          "القيم (disease/drug_name/test_name)NOT ABLICABLE label_encoders.json ");
    }

    
    final minV = _minValue!;
    final maxV = _maxValue!;
    final norm =
        ((testValue - minV) / (maxV - minV)).clamp(0.0, 1.0).toDouble();

   
    final input = [
      [diseaseId.toDouble(), drugId.toDouble(), testId.toDouble(), norm]
    ];
    final dosageCount = _dosageLabels!.length;
    final durationCount = _durationLabels!.length;
    final freqCount = _frequencyLabels!.length;

    final dosageOutput =
        List.generate(1, (_) => List.filled(dosageCount, 0.0));
    final durationOutput =
        List.generate(1, (_) => List.filled(durationCount, 0.0));
    final freqOutput =
        List.generate(1, (_) => List.filled(freqCount, 0.0));

    // Branch on a condition that affects logic flow.
    if (_dosageOutSlot == null ||
        _durationOutSlot == null ||
        _freqOutSlot == null) {
      throw Exception("⚠The model outputs are not initialized (output slots are null)");
    }

    final outputs = <int, Object>{
      _dosageOutSlot!: dosageOutput,
      _durationOutSlot!: durationOutput,
      _freqOutSlot!: freqOutput,
    };

    _interpreter.runForMultipleInputs([input], outputs);

    int argMax(List<double> list) {
      var maxIdx = 0;
      var maxVal = list[0];
      // Loop over a collection to apply logic.
      for (var i = 1; i < list.length; i++) {
        // Branch on a condition that affects logic flow.
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


  static Future<void> approveMedicationPrediction({
    required String patientId,
    required String medicationId,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('patient_profiles')
        .doc(patientId)
        .collection('medications')
        .doc(medicationId);

    // Await an asynchronous operation.
    final snap = await ref.get();
    // Branch on a condition that affects logic flow.
    if (!snap.exists) {
      print("❌ Medication not found to approve");
      return;
    }

    final data = snap.data()!;
    final pendingDosage = data['pending_dosage'];
    final pendingDuration = data['pending_duration'];
    final pendingFrequency = data['pending_frequency'];
    final pendingTestValue = data['pending_test_value'];

    // Branch on a condition that affects logic flow.
    if (pendingDosage == null &&
        pendingDuration == null &&
        pendingFrequency == null) {
      print("ℹ No pending_* values to approve");
      return;
    }

    // Await an asynchronous operation.
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
        "✅ Prediction approved and moved to main fields (dosage/duration/frequency)");
  }
}
