import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import 'OnboardingScreen.dart';

class RecommendationsScreen extends StatefulWidget {
  final String testName;
  final double value;

  const RecommendationsScreen({
    super.key,
    required this.testName,
    required this.value,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late Future<_RecoResult> _futureReco;

  @override
  void initState() {
    super.initState();
    _futureReco = _loadAndPredict();
  }

  /// تحميل JSON + تشغيل مودل TFLite
  Future<_RecoResult> _loadAndPredict() async {
    // 1) تحميل الوصف لكل تحليل
    final descStr = await rootBundle
        .loadString('assets/recommendations_models/descriptions.json');
    final Map<String, dynamic> descJson = jsonDecode(descStr);

    // اسم التحليل اللي نستخدمه كمفتاح في الـ JSON
    String canonicalName = widget.testName.trim();
    // لو الاسم كله داخل قوسين فقط نشيل القوسين الخارجيين ونترك أي شيء داخل الاسم مثل (ALT)
    if (canonicalName.startsWith('(') && canonicalName.endsWith(')')) {
      canonicalName =
          canonicalName.substring(1, canonicalName.length - 1).trim();
    }

    final description =
        (descJson[canonicalName] as String?) ?? 'No description available.';

    // 2) تحميل ال scaler
    final scalerStr = await rootBundle
        .loadString('assets/recommendations_models/scaler (1).json');
    final scalerJson = jsonDecode(scalerStr) as Map<String, dynamic>;
    final double vMin = (scalerJson['min'][0] as num).toDouble();
    final double vMax = (scalerJson['max'][0] as num).toDouble();
    final double scaledValue =
        (widget.value - vMin) / (vMax - vMin + 1e-8); // نفس اللي في بايثون

    // 3) تحميل label_encoders.json وعمل term → index
    final labelsStr = await rootBundle
        .loadString('assets/recommendations_models/label_encoders.json');
    final labelsJson = jsonDecode(labelsStr) as Map<String, dynamic>;
    final Map<String, dynamic> medMap =
        labelsJson['medical_term'] as Map<String, dynamic>;

    final Map<String, int> termToIndex = {};
    medMap.forEach((k, v) {
      termToIndex[v as String] = int.parse(k);
    });

    final int? termIndex = termToIndex[canonicalName];

    if (termIndex == null) {
      // ما لقينا هذا التحليل في المودل
      return _RecoResult(
        description: description,
        recommendation:
            'No lifestyle recommendations – this test is not covered by the AI model.',
      );
    }

    final int numTerms = medMap.length; // عدد التحاليل
    final int nInputs = numTerms + 1; // one-hot + value

    // 4) تجهيز input vector
    final inputVector = List<double>.filled(nInputs, 0.0);
    inputVector[termIndex] = 1.0; // one-hot
    inputVector[nInputs - 1] = scaledValue;

    // 5) تحميل target_encoders.json لمعرفة عدد الكلاسات
    final targetsStr = await rootBundle
        .loadString('assets/recommendations_models/target_encoders.json');
    final targetsJson = jsonDecode(targetsStr) as Map<String, dynamic>;
    final Map<String, dynamic> recMap =
        targetsJson['Recommendation'] as Map<String, dynamic>;
    final int numClasses = recMap.length;

    // 6) تشغيل المودل TFLite
    final interpreter = await tfl.Interpreter.fromAsset(
      'assets/recommendations_models/lab_reco_model.tflite',
    );

    final input = [inputVector];
    final output =
        List.generate(1, (_) => List.filled(numClasses, 0.0)); // [1, C]

    interpreter.run(input, output);

    final List<double> probs = output[0].cast<double>();

    // argmax
    int bestIdx = 0;
    double bestVal = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > bestVal) {
        bestVal = probs[i];
        bestIdx = i;
      }
    }

    final recKey = bestIdx.toString();
    final recObj = recMap[recKey] as Map<String, dynamic>?;
    final recommendation =
        (recObj?['recommendation'] as String?) ?? 'No recommendation found.';

    return _RecoResult(
      description: description,
      recommendation: recommendation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: OnboardingBackgroundPainter(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF2E3B52)),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 90, 20, 24),
                  child: FutureBuilder<_RecoResult>(
                    future: _futureReco,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      final valueStr = widget.value
                          .toStringAsFixed(widget.value % 1 == 0 ? 0 : 1);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Your Personalized\nRecommendations',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0E1B3D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Based on your latest medical analysis, here's what we\nsuggest to improve your health:",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: Color(0xFF6C7A92),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // أيقونة شوكة/سكين (يسار)
                          const _SideCircleAsset(
                            assetPath: 'assets/fork&knife.png',
                            alignLeft: true,
                            topSpacing: 0,
                          ),
                          const SizedBox(height: 8),

                          // الكرت 1: اسم التحليل + القيمة
                          _PillCard(
                            alignLeft: false,
                            background: Colors.white,
                            text: '${widget.testName}  |  Value: $valueStr',
                          ),

                          const SizedBox(height: 20),

                          // الكرت 2: الوصف
                          _PillCard(
                            text: data.description,
                            alignLeft: true,
                            background: const Color(0xFF5F78A9),
                            textColor: Colors.white,
                            elevation: 1.25,
                          ),

                          const SizedBox(height: 16),

                          // أيقونة كبسولة (يمين)
                          const _SideCircleAsset(
                            assetPath: 'assets/pill.png',
                            alignLeft: false,
                          ),
                          const SizedBox(height: 8),

                          // الكرت 3: التوصية من المودل
                          _PillCard(
                            text: data.recommendation,
                            alignLeft: false,
                            background: Colors.white,
                          ),

                          const SizedBox(height: 24),

                          // أيقونة سرنجة (يسار)
                          const _SideCircleAsset(
                            assetPath: 'assets/injection.png',
                            alignLeft: true,
                            topSpacing: 0,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// نتيجة التنبؤ: وصف + توصية
class _RecoResult {
  final String description;
  final String recommendation;

  _RecoResult({
    required this.description,
    required this.recommendation,
  });
}

/// بطاقة بشكل "حبّة" محاذاة يمين/يسار
class _PillCard extends StatelessWidget {
  final String text;
  final bool alignLeft;
  final Color background;
  final Color textColor;
  final double elevation;

  const _PillCard({
    required this.text,
    required this.alignLeft,
    required this.background,
    this.textColor = const Color(0xFF26334D),
    this.elevation = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    final card = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12 * elevation),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.3,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Row(
      mainAxisAlignment:
          alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [card],
    );
  }
}

/// أيقونة دائرية بصور من الأصول
class _SideCircleAsset extends StatelessWidget {
  final String assetPath;
  final bool alignLeft;
  final double topSpacing;

  const _SideCircleAsset({
    required this.assetPath,
    required this.alignLeft,
    this.topSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (!alignLeft) const Spacer(),
        Container(
          margin: EdgeInsets.only(
            left: alignLeft ? 0 : 8,
            right: alignLeft ? 8 : 0,
            top: topSpacing,
          ),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (alignLeft) const Spacer(),
      ],
    );
  }
}
