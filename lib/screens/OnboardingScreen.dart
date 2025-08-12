
import 'package:flutter/material.dart';
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

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

          
          _buildContent(context),

          
          _buildSkipButton(context),
        ],
      ),
    );
  }

  
  Widget _buildContent(BuildContext context) {
    
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.45,
      left: 20,
      right: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const Text(
            'Hello &\nWelcome!',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 82, 82, 82),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF555555),
                height: 1.5,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: 'ARVA ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: const Color.fromARGB(255, 9, 72, 135),
                  ),
                ),
                const TextSpan(
                  text: 'Is Here to Support \nYou At Every Step in Care',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 97, 97, 97),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildSkipButton(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 30,
      child: TextButton(
        onPressed: () {
          print("Skip button pressed!");
        },
        child: const Text(
          'skip',
          style: TextStyle(
            color: Color(0xFF444444),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}


class OnboardingBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;

    final topPaint = Paint()..color = const Color(0xFFE6E7FA);

    // vvv  هنا هو مكان التغيير  vvv
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
    final bottomPath = Path()
      // 1. نقطة البداية
      ..moveTo(-0.1, height * 0.5)

     

      // 3. الانحناء الثاني (المرتفع)
      ..cubicTo(
        width * 0.3, height * 1, // نقطة تحكم 1
        width * 1, height * 0.5,  // نقطة تحكم 2
        width * 1,       height * 0.3  // نقطة النهاية النهائية
      )

      // 4. إغلاق الشكل
      ..lineTo(width, height)
      ..lineTo(width, height)
      ..close();
    canvas.drawPath(bottomPath, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}