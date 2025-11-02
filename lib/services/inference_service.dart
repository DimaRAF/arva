// services/inference_service.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/lab_test.dart';
import 'model_assets.dart';

enum PredTri { low, normal, high }
enum DecisionSource { model, rule, unknown }

class PredResult {
  final PredTri tri;
  final DecisionSource source;
  const PredResult(this.tri, this.source);
}


class InferenceService {
  static Interpreter? _it;

  static Future<void> _ensure() async {
    await ModelAssets.ensureLoaded();
    if (_it != null) return;
    final data = await rootBundle.load('assets/model/medical_model.tflite');
    final f = File('${(await Directory.systemTemp.createTemp()).path}/m.tflite');
    await f.writeAsBytes(data.buffer.asUint8List());
    _it = await Interpreter.fromFile(f);
  }

  // مطابقة اسم التحليل كما هو في label_map.json (محاولة ذكية بسيطة)
  static int _encodeTestName(String code, String name) {
    final m = ModelAssets.nameToIdx!;
    if (m.containsKey(name)) return m[name]!;
    if (m.containsKey(code)) return m[code]!;
    // جرّبي مفاتيح توافق جزئي بالحروف الكبيرة
    final up = name.toUpperCase();
    for (final e in m.entries) {
      if (up.contains(e.key.toUpperCase())) return e.value;
    }
    // آخر حل: 0
    return 0;
  }

  static List<double> _scale(List<double> x) {
    final mu = ModelAssets.mean!, s = ModelAssets.scale!;
    return List<double>.generate(x.length, (i) => (x[i] - mu[i]) / s[i]);
  }

  /// يرجّع: probaAbnormal ∈ [0,1]
  static Future<double> predictAbnormalProb(LabTest t) async {
    await _ensure();
    final enc = _encodeTestName(t.code, t.name).toDouble();
    final feats = _scale([enc, t.value, t.refMin, t.refMax]);
    final input = [feats];
    final output = List.generate(1, (_) => List.filled(1, 0.0));
    _it!.run(input, output);
    return (output[0][0] as double);
  }

 static Future<PredResult> decide(LabTest t) async {
  await _ensure();

  final labels = ModelAssets.nameToIdx ?? const <String, int>{};
  final thMap  = ModelAssets.thresholds ?? const <String, double>{};

  // مفاتيح كما هي (نكتفي بـ trim فقط، بدون تغيير حالة الحروف)
  final codeKey = (t.code ?? '').trim();
  final nameKey = (t.name ?? '').trim();

  // هل التحليل معروف للمودل؟
  String? key;
  if (codeKey.isNotEmpty && labels.containsKey(codeKey)) {
    key = codeKey;
  } else if (nameKey.isNotEmpty && labels.containsKey(nameKey)) {
    key = nameKey;
  } else {
    // محاولة مطابقة حساسة للحالة لكن تسمح باختلاف بسيط في المسافات الطرفية فقط
    // (لو بدك Case-Insensitive Exact بدون Uppercasing ممكن تضيفي مقارنة toLowerCase هنا)
    for (final k in labels.keys) {
      if (k.trim() == codeKey || k.trim() == nameKey) {
        key = k;
        break;
      }
    }
  }

  if (key != null) {
    // ✅ القرار من المودل فقط
    final p  = await predictAbnormalProb(t);
    final th = thMap[key] ?? 0.5;
    final isAbn = p >= th;

    if (!isAbn) {
      return const PredResult(PredTri.normal, DecisionSource.model);
    }

    // إن توفر رينج، نستخدمه فقط لتحديد الاتجاه (عرض)
    final hasRange = t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;
    if (hasRange) {
      if (t.value < t.refMin) return const PredResult(PredTri.low,  DecisionSource.model);
      if (t.value > t.refMax) return const PredResult(PredTri.high, DecisionSource.model);
    }
    // لو ما في رينج أو داخل الرينج لكن المودل قال Abnormal → اعتبريها High افتراضياً
    return const PredResult(PredTri.high, DecisionSource.model);
  }

  // ❗️غير معروف للمودل → fallback بالرينج إن وُجد
  final hasRange = t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;
  if (hasRange) {
    if (t.value < t.refMin) return const PredResult(PredTri.low,  DecisionSource.rule);
    if (t.value > t.refMax) return const PredResult(PredTri.high, DecisionSource.rule);
    return const PredResult(PredTri.normal, DecisionSource.rule);
  }

  // لا مودل ولا رينج → قيمة فقط
  return const PredResult(PredTri.normal, DecisionSource.unknown);
}
}