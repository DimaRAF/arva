import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class MinMaxScalerLite {
  final List<double> min_;
  final List<double> max_;
  final List<double> featureRange;
  final List<String> featuresOrder;

  MinMaxScalerLite({
    required this.min_,
    required this.max_,
    required this.featureRange,
    required this.featuresOrder,
  });

  factory MinMaxScalerLite.fromJson(Map<String, dynamic> json) {
    return MinMaxScalerLite(
      min_: List<double>.from(json['min_'].map((x) => x.toDouble())),
      max_: List<double>.from(json['max_'].map((x) => x.toDouble())),
      featureRange: List<double>.from(json['feature_range'].map((x) => x.toDouble())),
      featuresOrder: List<String>.from(json['features_order']),
    );
  }

  List<double> normalizeVector(List<double> raw) {
    final out = <double>[];
    // Loop over a collection to apply logic.
    for (int i = 0; i < raw.length; i++) {
      final norm = (raw[i] - min_[i]) / (max_[i] - min_[i]);
      out.add(norm.clamp(featureRange[0], featureRange[1]));
    }
    return out;
  }

  List<double> denormalizeVector(List<double> norm) {
    final out = <double>[];
    // Loop over a collection to apply logic.
    for (int i = 0; i < norm.length; i++) {
      final val = norm[i] * (max_[i] - min_[i]) + min_[i];
      out.add(val);
    }
    return out;
  }
}

Future<MinMaxScalerLite> loadScalerFromAssets(String path) async {
  // Await an asynchronous operation.
  final jsonStr = await rootBundle.loadString(path);
  final Map<String, dynamic> data = jsonDecode(jsonStr);
  return MinMaxScalerLite.fromJson(data);
}
