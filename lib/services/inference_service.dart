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
    _it = Interpreter.fromFile(f);
  }

  
  static int _encodeTestName(String code, String name) {
    final m = ModelAssets.nameToIdx!;
    if (m.containsKey(name)) return m[name]!;
    if (m.containsKey(code)) return m[code]!;

    final up = name.toUpperCase();
    for (final e in m.entries) {
      if (up.contains(e.key.toUpperCase())) return e.value;
    }

    return 0;
  }

  static List<double> _scale(List<double> x) {
    final mu = ModelAssets.mean!, s = ModelAssets.scale!;
    return List<double>.generate(x.length, (i) => (x[i] - mu[i]) / s[i]);
  }


  static Future<double> predictAbnormalProb(LabTest t) async {
    await _ensure();
    final enc = _encodeTestName(t.code, t.name).toDouble();
    final feats = _scale([enc, t.value, t.refMin, t.refMax]);
    final input = [feats];
    final output = List.generate(1, (_) => List.filled(1, 0.0));
    _it!.run(input, output);
    return output[0][0];
  }

 static Future<PredResult> decide(LabTest t) async {
  await _ensure();

  final labels = ModelAssets.nameToIdx ?? const <String, int>{};
  final thMap  = ModelAssets.thresholds ?? const <String, double>{};

  
  final codeKey = (t.code ?? '').trim();
  final nameKey = (t.name ?? '').trim();


  String? key;
  if (codeKey.isNotEmpty && labels.containsKey(codeKey)) {
    key = codeKey;
  } else if (nameKey.isNotEmpty && labels.containsKey(nameKey)) {
    key = nameKey;
  } else {
    
    for (final k in labels.keys) {
      if (k.trim() == codeKey || k.trim() == nameKey) {
        key = k;
        break;
      }
    }
  }

  if (key != null) {
   
    final p  = await predictAbnormalProb(t);
    final th = thMap[key] ?? 0.5;
    final isAbn = p >= th;

    if (!isAbn) {
      return const PredResult(PredTri.normal, DecisionSource.model);
    }

   
    final hasRange = t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;
    if (hasRange) {
      if (t.value < t.refMin) return const PredResult(PredTri.low,  DecisionSource.model);
      if (t.value > t.refMax) return const PredResult(PredTri.high, DecisionSource.model);
    }
    
    return const PredResult(PredTri.high, DecisionSource.model);
  }

 
  final hasRange = t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;
  if (hasRange) {
    if (t.value < t.refMin) return const PredResult(PredTri.low,  DecisionSource.rule);
    if (t.value > t.refMax) return const PredResult(PredTri.high, DecisionSource.rule);
    return const PredResult(PredTri.normal, DecisionSource.rule);
  }


  return const PredResult(PredTri.normal, DecisionSource.unknown);
}
}