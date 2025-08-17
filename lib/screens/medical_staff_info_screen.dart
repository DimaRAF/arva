import 'package:flutter/material.dart';
import 'dart:math';

class MedicalStaffSignUpScreen extends StatelessWidget {
  const MedicalStaffSignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. نستخدم Stack كـ "body" رئيسي لوضع الطبقات فوق بعضها
      body: Stack(
        children: [
          // --- الطبقة الأولى: الخلفية المربعة المائلة ---
          CustomPaint(
            size: Size.infinite,
            painter: SignUpBackgroundPainter(),
          ),

          // --- الطبقة الثانية: المحتوى القابل للتمرير ---
          // نستخدم SafeArea لتجنب تداخل المحتوى مع حواف الشاشة العلوية
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // --- الجزء العلوي مع الصورة ---
                  // نضع الصورة داخل Stack لنتمكن من تحديد مكانها بدقة
                  SizedBox(
                    height: 280, // نعطي ارتفاعاً ثابتاً للجزء العلوي
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // تأكد من وضع الصورة في مجلد assets
                        Positioned(
                          top: 50, // نضبط المسافة من الأعلى
                          child: Image.asset(
                            'assets/doctors.png', // تأكد أن اسم الصورة صحيح
                            height: 220,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // --- الجزء السفلي مع حقول الإدخال ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        const Text(
                          "Nice to have you here",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        const SizedBox(height: 30),

                        // حقول الإدخال
                        _buildTextField(icon: Icons.person_outline, hintText: 'User Name'),
                        const SizedBox(height: 15),
                        _buildTextField(icon: Icons.email_outlined, hintText: 'Email'),
                        const SizedBox(height: 15),
                        _buildTextField(icon: Icons.lock_outline, hintText: 'Password', obscureText: true),
                        const SizedBox(height: 15),
                        _buildTextField(icon: Icons.lock_outline, hintText: 'Confirm Password', obscureText: true),
                        const SizedBox(height: 30),

                        // زر إنشاء الحساب
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A7A9A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('Sign up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // رابط تسجيل الدخول
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                            children: [
                              const TextSpan(text: "Already have an account? "),
                              TextSpan(
                                text: "Login",
                                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20), // مساحة إضافية في الأسفل
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- الطبقة الثالثة: زر الرجوع ---
          // نضعه هنا ليكون فوق كل شيء آخر
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: const Color(0xFF5A7A9A),
              child: const Icon(Icons.arrow_back, color: Colors.white),
              mini: true,
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء حقول الإدخال
  Widget _buildTextField({required IconData icon, required String hintText, bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// كلاس رسم الخلفية (يبقى كما هو)
class SignUpBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final tealPaint = Paint()..color = const Color(0xFFC2DCDD);
    canvas.save();
    canvas.translate(width * 0.8, height * 0.05);
    canvas.rotate(-pi / 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: width * 0.8, height: 150),
        const Radius.circular(30),
      ),
      tealPaint,
    );
    canvas.restore();

    final purplePaint = Paint()..color = const Color(0xFFE6E7FA);
    canvas.save();
    canvas.translate(width * 0.3, height * 0.1);
    canvas.rotate(pi / 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: width, height: 150),
        const Radius.circular(30),
      ),
      purplePaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
