import 'package:flutter/material.dart';
import 'OnboardingScreen.dart'; // الخلفية المتموّجة

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

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
                  child: Column(
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

                      // البطاقة 1 — يمين
                      const _PillCard(
                        text:
                            'Eat meals full of natural fibers that help the level of iron in the blood',
                        alignLeft: false,
                        background: Colors.white,
                      ),

                      const SizedBox(height: 20),

                      // البطاقة 2 — يسار (زرقاء)
                      const _PillCard(
                        text: 'Oral iron supplements.',
                        alignLeft: true,
                        background: Color(0xFF5F78A9),
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

                      // البطاقة 3 — يمين
                      const _PillCard(
                        text: 'Taking an intravenous iron injection.',
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
