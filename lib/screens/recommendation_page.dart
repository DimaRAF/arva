import 'package:flutter/material.dart';

class BloodTest extends StatelessWidget {
  const BloodTest({super.key});

  @override
  Widget build(BuildContext context) {
    
    final bg = const Color(0xFF5FAAB1);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Container(
          //  الفريم الداخلي حولته أبيض
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Color(0x19000000), blurRadius: 40),
            ],
          ),
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // العنوان + زر إغلاق
              Row(
                children: [
                  _CircleIconButton(
                    onTap: () => Navigator.of(context).maybePop(),
                    icon: Icons.close,
                    color: const Color(0xFF4C6EA0),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: Color(0xFF0E1B3D),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), //   موازنة زر حق الإغلاق
                ],
              ),
              const SizedBox(height: 16),

              //  التمرير
              Expanded(
                child: ListView(
                  children: const [
                    BloodCard(
                      title: 'WBC',
                      status: 'slightly elevated',
                      valueText: '11.7',
                      startLabel: '4×10⁹/L',
                      endLabel: '11×10⁹/L',
                      trackColor: Color(0xFFFCC944),
                      fillToPercent: 0.85,
                      cardTint: Color(0x54F5475C), // وردي شفاف
                    ),
                    SizedBox(height: 12),
                    BloodCard(
                      title: 'MCV',
                      status: 'slightly lower',
                      valueText: '75.4',
                      startLabel: '80 fl',
                      endLabel: '95 fl',
                      trackColor: Color(0xFFFCC944),
                      fillToPercent: 0.35,
                      cardTint: Color(0x54F5475C),
                    ),
                    SizedBox(height: 12),
                    BloodCard(
                      title: 'MCH',
                      status: 'slightly lower',
                      valueText: '24.8',
                      startLabel: '31 pg',
                      endLabel: '36 pg',
                      trackColor: Color(0xFFFCC944),
                      fillToPercent: 0.30,
                      cardTint: Color(0x51FCD777), // أصفر فاتح
                    ),
                    SizedBox(height: 12),
                    BloodCard(
                      title: 'Hct',
                      status: 'normal',
                      valueText: '41',
                      startLabel: '37',
                      endLabel: '47',
                      trackColor: Color(0xFFFCC944),
                      fillToPercent: 0.50,
                      cardTint: Color(0xFFF6F7F7),
                    ),
                    SizedBox(height: 12),
                    BloodCard(
                      title: 'Hgb',
                      status: 'normal',
                      valueText: '13.5',
                      startLabel: 'F: 12.0 g/dL\nM: 13.5 g/dL',
                      endLabel:   'F: 14.0 g/dL\nM: 17.0 g/dL',
                      trackColor: Color(0xFFFCC944),
                      fillToPercent: 0.55,
                      cardTint: Color(0xFFF6F7F7),
                    ),
                    SizedBox(height: 12),
                    BloodCard(
                      title: 'Platelet count',
                      status: 'normal',
                      valueText: '376',
                      startLabel: '150×10⁹/L',
                      endLabel: '450×10⁹/L',
                      trackColor: Color(0xFFFCC944),
                      fillToPercent: 0.80,
                      cardTint: Color(0xFFF6F7F7),
                    ),
                    SizedBox(height: 12),
                    BloodCard(
                      title: 'Neutrophils',
                      status: 'normal',
                      valueText: '56.1',
                      startLabel: '40',
                      endLabel: '70',
                      trackColor: Color(0xFFFCC944),
                      fillToPercent: 0.60,
                      cardTint: Color(0xFFF6F7F7),
                    ),
                    SizedBox(height: 12),
                    BloodCard(
                      title: 'Lymphocytes',
                      status: 'normal',
                      valueText: '38.5',
                      startLabel: '20',
                      endLabel: '40',
                      trackColor: Color(0xFFFCC944),
                      fillToPercent: 0.50,
                      cardTint: Color(0xFFF6F7F7),
                    ),
                    SizedBox(height: 16),
                    _NoteBox(
                      text:
                          'Overall, the CBC results suggest a possible infection or inflammation. '
                          'Consult a healthcare professional to interpret results and recommend next steps.',
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BloodCard extends StatelessWidget {
  final String title;
  final String status;
  final String valueText;
  final String startLabel;
  final String endLabel;
  final Color trackColor;
  final double fillToPercent; // 0.0 -> 1.0
  final Color cardTint;

  const BloodCard({
    super.key,
    required this.title,
    required this.status,
    required this.valueText,
    required this.startLabel,
    required this.endLabel,
    required this.trackColor,
    required this.fillToPercent,
    required this.cardTint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardTint,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const _BloodDrop(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('($title)',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF17342F),
                        )),
                    Text(status,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF617D79),
                        )),
                  ],
                ),
              ),
              Text(
                valueText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17342F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RangeBar(
            fillPercent: fillToPercent,
            tickColor: trackColor,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(startLabel, style: const TextStyle(fontSize: 10, color: Color(0xFF617D79))),
              Text(endLabel,   style: const TextStyle(fontSize: 10, color: Color(0xFF617D79))),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  final double fillPercent; // 0..1
  final Color tickColor;

  const _RangeBar({required this.fillPercent, required this.tickColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final filled = (w * fillPercent).clamp(0, w);
        return Stack(
          children: [
            // الخلفية: أصفر -> أخضر -> أحمر (مبسطة)
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFCC944), Color(0xFF47C972), Color(0xFFE74C5B)],
                ),
              ),
            ),
            // موشر صغير
            Positioned(
              left: filled - 6,
              top: -4,
              child: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF17342F)),
            ),
          ],
        );
      },
    );
  }
}

class _BloodDrop extends StatelessWidget {
  const _BloodDrop();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.red.shade300,
      child: const Icon(Icons.bloodtype, color: Colors.white),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  const _CircleIconButton({required this.onTap, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String text;
  const _NoteBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: const Color(0xFFF6F7F7), borderRadius: BorderRadius.circular(12)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
      ),
    );
  }
}

