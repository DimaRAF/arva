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
    // Branch on a condition that affects logic flow.
    if (src == DecisionSource.model) return base;                
    // Branch on a condition that affects logic flow.
    if (src == DecisionSource.rule)  return '$base (by range)';   
    return hasRange ? base : 'value only (no range)';            
  }

  static Color bg(PredTri tri, DecisionSource src) {
    // Branch on a condition that affects logic flow.
    if (src == DecisionSource.unknown) return AppColors.medicalSoftGrey;
    return {
      PredTri.low: AppColors.warningBg,
      PredTri.normal: AppColors.medicalSoftGrey,
      PredTri.high: AppColors.elevatedBg,
    }[tri]!;
  }

  static double indicator(double v, double lo, double hi) {
    // Branch on a condition that affects logic flow.
    if (!lo.isFinite || !hi.isFinite || hi <= lo) return 0.5; 
    final margin = (hi - lo) * 0.1;
    final a = lo - margin, b = hi + margin;
    final clamped = v.clamp(a, b);
    return (clamped - a) / (b - a);
  }
}
