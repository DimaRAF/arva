import 'package:flutter/material.dart';

// هذا هو الكلاس الخاص بالخلفية، وهو نفسه المستخدم في الشاشة السابقة
// يمكنك وضعه في ملف منفصل واستيراده لتجنب تكرار الكود
class OnboardingBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    
    final height = size.height;
    final width = size.width;

    final topPaint = Paint()..color = const Color(0xFFE6E7FA);

    
    final topPath = Path()
      ..moveTo(0, height * 0.4) // 1. نبدأ من هنا

      // 2. نرسم الانحناء الأول (الأيسر)
      ..cubicTo(
        width * 0.8, height * 0.5, // نقطة تحكم 1
        width * 0.2,  height * 0.26,  // نقطة تحكم 2
        width ,  height * 0.30   // نقطة النهاية للمنحنى الأول
      )

      

      // 4. نغلق الشكل
      ..lineTo(width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(topPath, topPaint);

    
    
    // لون الشكل السفلي (أزرق مخضر فاتح)
    final bottomPaint = Paint()..color = const Color(0xFFC2DCDD);
    // --- 2. المنحنى السفلي المتموج ---
    
    final bottomPath = Path()
      // نقطة البداية (من اليمين)
      ..moveTo(width, height * 0.7)
      // الموجة الأولى (اليمنى)
      ..cubicTo(
        width * 0.4, height * 0.6, // نقطة تحكم 1
        width * 0.65, height * 0.85, // نقطة تحكم 2
        width * 0.35, height * 0.8   // نهاية الموجة الأولى
      )
      // الموجة الثانية (اليسرى)
      ..cubicTo(
        width * 0.10, height * 0.79, // نقطة تحكم 1
        0,            height * 0.9,  // نقطة تحكم 2
        width * 0.02, height      // نقطة النهاية النهائية
      )
      // إغلاق الشكل من الأسفل
      ..lineTo(width, height)
      ..close();
    canvas.drawPath(bottomPath, bottomPaint);

// --- الشكل البنفسجي الثاني (الخلفي) ---
// --- الشكل البنفسجي الثاني (الخلفي) ---
// --- الشكل البنفسجي الثاني (الخلفي) على اليمين ---
final middlePaint = Paint()
  ..color = const Color.fromARGB(255, 206, 208, 245).withOpacity(0.7);

final middlePath = Path()
  // نبدأ خارج الشاشة من جهة اليمين قرب الأعلى
  ..moveTo(width * 1.2, height * 0.001)

  // رأس الفقاعة (ينحني لليسار بالجزء العلوي)
  ..cubicTo(
    width * 1.08, height * 0.06,  // cp1
    width * 0.9, height * 0.007,  // cp2
    width * 0.7, height * 0.2 // end1
  )

  // الانحناء الأوسط الذي ينزل باتجاه المركز
  ..cubicTo(
    width * 0.3, height * 0.3,  // cp3
    width * 0.27, height * 0.5,  // cp4
    width * 0.7, height * 0.6   // end2
  )

  // يرجع للخارج على اليمين ليكمل شكل الفقاعة ويقفلها
  ..cubicTo(
    width * 0.99, height * 1.0,  // cp5
    width * 1.0, height * 0.35,  // cp6 (خارج الشاشة قليلاً ليعطي انبسام)
    width * 6.8, height * 2.07 // end3 (نقطة قريبة من الأعلى على اليمين)
  )
  ..close();

canvas.drawPath(middlePath, middlePaint);


  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}


// --- الواجهة الرئيسية لصفحة اختيار الدور ---
class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. الخلفية المتموجة
          CustomPaint(
            size: Size.infinite,
            painter: OnboardingBackgroundPainter(),
          ),

          // 2. المحتوى الرئيسي
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose your role :',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E5B7A),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleCard(
                      icon: Icons.medical_services_outlined,
                      label: 'Medical staff',
                    ),
                    _buildRoleCard(
                      icon: Icons.personal_injury_outlined,
                      label: '   Patient   ',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. زر السهم في الأسفل
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF5A7A9A),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء كرت اختيار الدور
  Widget _buildRoleCard({required IconData icon, required String label}) {
    return Column(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5A7A9A), width: 9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, size: 70, color: const Color(0xFF5A7A9A)),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5A7A9A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}