import 'package:flutter/material.dart';
import 'choose_role_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

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
          const SizedBox(height: 50),
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
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChooseRoleScreen()),
            );
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

    
    final topPath = Path()
      ..moveTo(0, height * 0.4) 

      
      ..cubicTo(
        width * 0.8, height * 0.5,
        width * 0.2,  height * 0.26, 
        width ,  height * 0.30  
      )

      

     
      ..lineTo(width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(topPath, topPaint);

    
    
    
    final bottomPaint = Paint()..color = const Color(0xFFC2DCDD);
   
    
    final bottomPath = Path()
     
      ..moveTo(width, height * 0.7)
    
      ..cubicTo(
        width * 0.4, height * 0.6, 
        width * 0.65, height * 0.85, 
        width * 0.35, height * 0.8   
      )
      
      ..cubicTo(
        width * 0.10, height * 0.79, 
        0,            height * 0.9,  
        width * 0.02, height      
      )
      
      ..lineTo(width, height)
      ..close();
    canvas.drawPath(bottomPath, bottomPaint);



final middlePaint = Paint()
  ..color = const Color.fromARGB(255, 206, 208, 245).withOpacity(0.7);

final middlePath = Path()
  
  ..moveTo(width * 1.2, height * 0.001)

 
  ..cubicTo(
    width * 1.08, height * 0.06,  // cp1
    width * 0.9, height * 0.007,  // cp2
    width * 0.7, height * 0.2 // end1
  )

  
  ..cubicTo(
    width * 0.3, height * 0.3,  // cp3
    width * 0.27, height * 0.5,  // cp4
    width * 0.7, height * 0.6   // end2
  )


  ..cubicTo(
    width * 0.99, height * 1.0,  // cp5
    width * 1.0, height * 0.35,  // cp6
    width * 6.8, height * 2.07 // end3 
  )
  ..close();

canvas.drawPath(middlePath, middlePaint);


  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}