import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'medical_staff_login_screen.dart';
import 'auth_screen.dart';

class MedicalStaffSignUpScreen extends StatefulWidget {
  const MedicalStaffSignUpScreen({Key? key}) : super(key: key);

  @override
  State<MedicalStaffSignUpScreen> createState() => _MedicalStaffSignUpScreenState();
}

class _MedicalStaffSignUpScreenState extends State<MedicalStaffSignUpScreen> {
  // 2. أضفنا متغيرات لتتبع حالة رؤية كلمتي المرور
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // الطبقة الأولى: الخلفية
          CustomPaint(
            size: Size.infinite,
            painter: SignUpBackgroundPainter(),
          ),

          // الطبقة الثانية: المحتوى
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // الجزء العلوي مع الصورة
                  SizedBox(
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -10,
                          child: Image.asset(
                            'assets/doctors.png',
                            height: 300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // الجزء السفلي مع حقول الإدخال
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Nice to have you here",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        const SizedBox(height: 20),

                        // حقول الإدخال العادية
                        _buildTextField(icon: Icons.person_outline, hintText: 'User Name'),
                        const SizedBox(height: 15),
                        _buildTextField(icon: Icons.email_outlined, hintText: 'Email'),
                        const SizedBox(height: 15),

                        
                        _buildPasswordTextField(
                          hintText: 'Password',
                          isVisible: _passwordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                        const SizedBox(height: 15),

                        // حقل تأكيد كلمة المرور مع أيقونة العين
                        _buildPasswordTextField(
                          hintText: 'Confirm Password',
                          isVisible: _confirmPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _confirmPasswordVisible = !_confirmPasswordVisible;
                            });
                          },
                        ),
                        
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
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const MedicalStaffLoginScreen()),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // الطبقة الثالثة: زر الرجوع
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen(userRole: 'Medical Staff')),
                );
              },
              backgroundColor: const Color(0xFF5A7A9A),
              child: const Icon(Icons.arrow_back, color: Colors.white),
              mini: true,
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة للحقول العادية
  Widget _buildTextField({required IconData icon, required String hintText}) {
    return TextField(
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

  // دالة مساعدة مخصصة لحقول كلمة المرور
  Widget _buildPasswordTextField({
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
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

    final tealPaint = Paint()..color = const Color(0xFFBFDDE0);
    canvas.save();
    canvas.translate(width * 0.6, height * 0.03);
    canvas.rotate(pi / 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: width * 0.8, height: 150),
        const Radius.circular(30),
      ),
      tealPaint,
    );
    canvas.restore();

    final purplePaint = Paint()..color = const Color(0xFFC6B4DE);
    canvas.save();
    canvas.translate(width * 0.2, height * 0.03);
    canvas.rotate(pi / 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: width, height: 200),
        const Radius.circular(30),
      ),
      purplePaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}