// services/model_assets.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ModelAssets {
  static Map<int, String>? idxToName;
  static Map<String, int>? nameToIdx;   // name (كما في التدريب) -> index
  static List<double>? mean, scale;     // طولهم 4: [enc, value, low, high]
  static Map<String, double>? thresholds;

  static Future<void> ensureLoaded() async {
    if (idxToName != null) return;

    // label_map.json: { "0": "ALT", "1": "AST", ... }
    final lm = jsonDecode(await rootBundle.loadString('assets/model/label_map.json'))
        as Map<String, dynamic>;
    idxToName = { for (final e in lm.entries) int.parse(e.key): e.value as String };
    nameToIdx = { for (final e in idxToName!.entries) e.value: e.key };

    // scaler.json: {"mean":[...4...], "scale":[...4...]}
    final sc = jsonDecode(await rootBundle.loadString('assets/model/scaler.json'));
    mean  = (sc['mean']  as List).map((e) => (e as num).toDouble()).toList();
    scale = (sc['scale'] as List).map((e) => (e as num).toDouble()).toList();

    // thresholds.json: {"WBC": 0.63, "MCV": 0.41, ...}
    final th = jsonDecode(await rootBundle.loadString('assets/model/thresholds.json'))
        as Map<String, dynamic>;
    thresholds = th.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}
