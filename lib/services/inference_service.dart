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
    // Await an asynchronous operation.
    await ModelAssets.ensureLoaded();
    // Branch on a condition that affects logic flow.
    if (_it != null) return;
    // Await an asynchronous operation.
    final data = await rootBundle.load('assets/model/medical_model.tflite');
    // Await an asynchronous operation.
    final f = File('${(await Directory.systemTemp.createTemp()).path}/m.tflite');
    // Await an asynchronous operation.
    await f.writeAsBytes(data.buffer.asUint8List());
    _it = Interpreter.fromFile(f);
  }

  
  static int _encodeTestName(String code, String name) {
    final m = ModelAssets.nameToIdx!;
    // Branch on a condition that affects logic flow.
    if (m.containsKey(name)) return m[name]!;
    // Branch on a condition that affects logic flow.
    if (m.containsKey(code)) return m[code]!;

    final up = name.toUpperCase();
    // Loop over a collection to apply logic.
    for (final e in m.entries) {
      // Branch on a condition that affects logic flow.
      if (up.contains(e.key.toUpperCase())) return e.value;
    }

    return 0;
  }

  static List<double> _scale(List<double> x) {
    final mu = ModelAssets.mean!, s = ModelAssets.scale!;
    return List<double>.generate(x.length, (i) => (x[i] - mu[i]) / s[i]);
  }


  static Future<double> predictAbnormalProb(LabTest t) async {
    // Await an asynchronous operation.
    await _ensure();
    final enc = _encodeTestName(t.code, t.name).toDouble();
    final feats = _scale([enc, t.value, t.refMin, t.refMax]);
    final input = [feats];
    final output = List.generate(1, (_) => List.filled(1, 0.0));
    _it!.run(input, output);
    return output[0][0];
  }

 static Future<PredResult> decide(LabTest t) async {
  // Await an asynchronous operation.
  await _ensure();

  final labels = ModelAssets.nameToIdx ?? const <String, int>{};
  final thMap  = ModelAssets.thresholds ?? const <String, double>{};

  
  final codeKey = (t.code ?? '').trim();
  final nameKey = (t.name ?? '').trim();


  String? key;
  // Branch on a condition that affects logic flow.
  if (codeKey.isNotEmpty && labels.containsKey(codeKey)) {
    key = codeKey;
  } else if (nameKey.isNotEmpty && labels.containsKey(nameKey)) {
    key = nameKey;
  } else {
    
    // Loop over a collection to apply logic.
    for (final k in labels.keys) {
      // Branch on a condition that affects logic flow.
      if (k.trim() == codeKey || k.trim() == nameKey) {
        key = k;
        break;
      }
    }
  }

  // Branch on a condition that affects logic flow.
  if (key != null) {
   
    // Await an asynchronous operation.
    final p  = await predictAbnormalProb(t);
    final th = thMap[key] ?? 0.5;
    final isAbn = p >= th;

    // Branch on a condition that affects logic flow.
    if (!isAbn) {
      return const PredResult(PredTri.normal, DecisionSource.model);
    }

   
    // Detect whether a valid reference range exists.
    final hasRange = t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;
    // Branch on a condition that affects logic flow.
    if (hasRange) {
      // Branch on a condition that affects logic flow.
      if (t.value < t.refMin) return const PredResult(PredTri.low,  DecisionSource.model);
      // Branch on a condition that affects logic flow.
      if (t.value > t.refMax) return const PredResult(PredTri.high, DecisionSource.model);
    }
    
    return const PredResult(PredTri.high, DecisionSource.model);
  }

 
  // Detect whether a valid reference range exists.
  final hasRange = t.refMin.isFinite && t.refMax.isFinite && t.refMax > t.refMin;
  // Branch on a condition that affects logic flow.
  if (hasRange) {
    // Branch on a condition that affects logic flow.
    if (t.value < t.refMin) return const PredResult(PredTri.low,  DecisionSource.rule);
    // Branch on a condition that affects logic flow.
    if (t.value > t.refMax) return const PredResult(PredTri.high, DecisionSource.rule);
    return const PredResult(PredTri.normal, DecisionSource.rule);
  }


  return const PredResult(PredTri.normal, DecisionSource.unknown);
}
}