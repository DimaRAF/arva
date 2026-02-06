import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ModelAssets {
  static Map<int, String>? idxToName;
  static Map<String, int>? nameToIdx;  
  static List<double>? mean, scale;    
  static Map<String, double>? thresholds;

  static Future<void> ensureLoaded() async {
    // Branch on a condition that affects logic flow.
    if (idxToName != null) return;

    // Await an asynchronous operation.
    final lm = jsonDecode(await rootBundle.loadString('assets/model/label_map.json'))
        as Map<String, dynamic>;
    idxToName = { for (final e in lm.entries) int.parse(e.key): e.value as String };
    nameToIdx = { for (final e in idxToName!.entries) e.value: e.key };

    // Await an asynchronous operation.
    final sc = jsonDecode(await rootBundle.loadString('assets/model/scaler.json'));
    mean  = (sc['mean']  as List).map((e) => (e as num).toDouble()).toList();
    scale = (sc['scale'] as List).map((e) => (e as num).toDouble()).toList();

    // Await an asynchronous operation.
    final th = jsonDecode(await rootBundle.loadString('assets/model/thresholds.json'))
        as Map<String, dynamic>;
    thresholds = th.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}
