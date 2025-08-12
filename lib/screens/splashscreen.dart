import 'dart:async';
import 'package:flutter/material.dart';
import 'OnboardingScreen.dart';

// --- SplashScreen converted to a StatefulWidget ---
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Create a timer that runs for 5 seconds.
    Timer(
      const Duration(seconds: 5),
      () {
        // After 5 seconds, navigate to the HomePage.
        // We use pushReplacement to prevent the user from going back to the splash screen.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // The UI of the splash screen remains the same.
    return Scaffold(
      body: CustomPaint(
        painter: SplashBackgroundPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo1.png',
                width: 150,
                height: 150,
              ),
              const Text(
                "ARVA",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 3),
              const Text(
                "Smarter Care, Anywhere",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// The CustomPainter for the background remains unchanged.
class SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;

    final backgroundPaint = Paint()..color = const Color(0xFF5A9D9D);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);

    final lightTealPaint = Paint()..color = const Color(0xFF7FB3B4);
    final lightTealPath = Path()
      ..moveTo(0, height * 0.18)
      ..quadraticBezierTo(width * 0.5, height * 0.35, width, height * 0.15)
      ..lineTo(width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(lightTealPath, lightTealPaint);

    final lavenderPaint = Paint()..color = const Color(0xFFD9D9F3);
    final lavenderPath = Path()
      ..moveTo(0, height * 0.12)
      ..quadraticBezierTo(width * 0.55, height * 0.22, width, height * 0.08)
      ..lineTo(width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(lavenderPath, lavenderPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, height * 0.86)
      ..quadraticBezierTo(
          width * 0.5, height * 0.81, width * 0.95, height * 0.84);
    canvas.drawPath(path1, linePaint);

    final path2 = Path()
      ..moveTo(0, height * 0.88)
      ..quadraticBezierTo(
          width * 0.5, height * 0.83, width * 0.95, height * 0.86);
    canvas.drawPath(path2, linePaint);

    final path3 = Path()
      ..moveTo(0, height * 0.90)
      ..quadraticBezierTo(
          width * 0.5, height * 0.85, width * 0.95, height * 0.88);
    canvas.drawPath(path3, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}


