// services/ui_mapping.dart
import 'package:flutter/material.dart';
import '../screens/results_page.dart' show AppColors;
import 'inference_service.dart';

class UiMapping {
  static String status(PredTri tri, DecisionSource src, {bool hasRange = true}) {
    final base = {
      PredTri.low: 'slightly lower',
      PredTri.normal: 'normal',
      PredTri.high: 'slightly elevated',
    }[tri]!;
    if (src == DecisionSource.model) return base;                 // من المودل
    if (src == DecisionSource.rule)  return '$base (by range)';   // قاعدة
    return hasRange ? base : 'value only (no range)';             // بدون حدود
  }

  static Color bg(PredTri tri, DecisionSource src) {
    if (src == DecisionSource.unknown) return AppColors.medicalSoftGrey;
    return {
      PredTri.low: AppColors.warningBg,
      PredTri.normal: AppColors.medicalSoftGrey,
      PredTri.high: AppColors.elevatedBg,
    }[tri]!;
  }

  static double indicator(double v, double lo, double hi) {
    if (!lo.isFinite || !hi.isFinite || hi <= lo) return 0.5; // وسط إذا ما في رينج
    final margin = (hi - lo) * 0.1;
    final a = lo - margin, b = hi + margin;
    final clamped = v.clamp(a, b);
    return (clamped - a) / (b - a);
  }
}
